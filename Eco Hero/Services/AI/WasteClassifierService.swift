//
//  WasteClassifierService.swift
//  Eco Hero
//
//  Machine learning service for real-time waste classification using Vision Framework.
//  Classifies waste items into: Recycle and Compost categories.
//
//  Created by Rishabh Bansal on 11/15/25.
//

import AVFoundation
import CoreImage
import CoreML
import Vision
import Observation

@Observable
final class WasteClassifierService: NSObject {
    enum AuthorizationState {
        case unknown
        case allowed
        case denied
    }

    enum ModelState {
        case notLoaded
        case loading
        case ready(VNCoreMLModel)
        case failed(Error)
    }

    // MARK: - Public Properties
    private(set) var authorizationState: AuthorizationState = .unknown
    private(set) var predictedBin: WasteBin = .recycle
    private(set) var confidence: Double = 0.0
    private(set) var modelState: ModelState = .notLoaded
    private(set) var isUsingFallback: Bool = false

    let session = AVCaptureSession()

    // MARK: - Private Properties
    private let outputQueue = DispatchQueue(label: "eco.hero.waste.classifier")
    private let visionQueue = DispatchQueue(label: "eco.hero.vision", qos: .userInitiated)
    private let ciContext = CIContext()
    private var isSessionConfigured = false
    private let sessionQueue = DispatchQueue(label: "eco.hero.camera.session")

    private var visionModel: VNCoreMLModel?
    private var classificationRequest: VNCoreMLRequest?

    // MARK: - Rolling Average Properties
    private var predictionBuffer: [(bin: WasteBin, confidence: Double)] = []
    private let bufferSize: Int = 15  // ~0.5 seconds at 30fps for smoother results
    private let stabilityThreshold: Double = 0.6  // Minimum confidence to update display

    // MARK: - Initialization
    override init() {
        super.init()
        Task {
            await loadMLModel()
            await evaluateAuthorization()
        }
    }

    // MARK: - ML Model Loading
    @MainActor
    private func loadMLModel() async {
        modelState = .loading

        do {
            // Try to load the CoreML model
            guard let modelURL = Bundle.main.url(forResource: "WasteClassifier", withExtension: "mlmodelc") else {
                throw NSError(domain: "WasteClassifier", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "WasteClassifier.mlmodelc not found in bundle. Please train and add the model."
                ])
            }

            let mlModel = try MLModel(contentsOf: modelURL)
            let visionModel = try VNCoreMLModel(for: mlModel)

            // Create classification request
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                self?.handleClassificationResults(request: request, error: error)
            }

            request.imageCropAndScaleOption = .centerCrop

            self.visionModel = visionModel
            self.classificationRequest = request
            self.modelState = .ready(visionModel)
            self.isUsingFallback = false

            print("✅ WasteClassifier model loaded successfully")

        } catch {
            print("⚠️ Failed to load WasteClassifier model: \(error.localizedDescription)")
            print("   Falling back to color-based heuristic")
            modelState = .failed(error)
            isUsingFallback = true
        }
    }

    @MainActor
    func requestAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationState = granted ? .allowed : .denied
            if granted { configureSessionIfNeeded() }
        case .authorized:
            authorizationState = .allowed
            configureSessionIfNeeded()
        default:
            authorizationState = .denied
        }
    }

    @MainActor
    private func evaluateAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            authorizationState = .allowed
            configureSessionIfNeeded()
        case .notDetermined:
            authorizationState = .unknown
        default:
            authorizationState = .denied
        }
    }

    @MainActor
    func startSession() {
        guard authorizationState == .allowed else { return }
        configureSessionIfNeeded()
        // Clear prediction buffer for fresh start
        predictionBuffer.removeAll()
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    @MainActor
    func stopSession() {
        // Clear prediction buffer when stopping
        predictionBuffer.removeAll()
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureSessionIfNeeded() {
        // This function is called from MainActor contexts. To avoid blocking the main
        // thread, we dispatch the configuration to a background queue.
        guard !isSessionConfigured else { return }

        // Set the flag immediately on the main thread to prevent re-entrancy.
        isSessionConfigured = true

        sessionQueue.async {
            self.session.beginConfiguration()

            var configurationSucceeded = false
            defer {
                self.session.commitConfiguration()
                if !configurationSucceeded {
                    // If configuration fails, reset the flag on the main thread.
                    Task { @MainActor in
                        self.isSessionConfigured = false
                    }
                }
            }

            self.session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                return
            }
            self.session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.outputQueue)
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            guard self.session.canAddOutput(output) else {
                return
            }
            self.session.addOutput(output)
            if let connection = output.connections.first,
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            
            configurationSucceeded = true
        }
    }

    // MARK: - Vision-based Classification (Real ML)
    nonisolated private func classifyWithVision(pixelBuffer: CVPixelBuffer, request: VNCoreMLRequest) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        let localRequest = request
        let localBuffer = pixelBuffer

        visionQueue.async { [weak self] in
            do {
                try handler.perform([localRequest])
            } catch {
                print("⚠️ Vision request failed: \(error.localizedDescription)")
                // Fall back to color detection on error
                self?.classifyWithColorHeuristic(pixelBuffer: localBuffer)
            }
        }
    }

    nonisolated private func handleClassificationResults(request: VNRequest, error: Error?) {
        if let error = error {
            print("⚠️ Classification error: \(error.localizedDescription)")
            return
        }

        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            print("⚠️ No classification results")
            return
        }

        // Map model output to WasteBin enum
        let bin = mapClassificationToBin(classification: topResult.identifier)
        let confidence = Double(topResult.confidence)

        Task { @MainActor in
            self.updateRollingAverage(newBin: bin, newConfidence: confidence)
        }
    }

    nonisolated private func mapClassificationToBin(classification: String) -> WasteBin {
        // Handle various possible label formats from the ML model
        let normalized = classification.lowercased()

        // Map dataset labels to WasteBin enum
        // O/organic -> compost, R/recyclable -> recycle
        if normalized.contains("recycle") || normalized == "r" {
            return .recycle
        } else if normalized.contains("compost") || normalized.contains("organic") || normalized == "o" {
            return .compost
        } else {
            // Default to recycle for unknown classifications
            print("⚠️ Unknown classification: \(classification), defaulting to recycle")
            return .recycle
        }
    }

    // MARK: - Rolling Average Calculation
    @MainActor
    private func updateRollingAverage(newBin: WasteBin, newConfidence: Double) {
        // Add new prediction to buffer
        predictionBuffer.append((bin: newBin, confidence: newConfidence))

        // Remove oldest if buffer exceeds size
        if predictionBuffer.count > bufferSize {
            predictionBuffer.removeFirst()
        }

        // Need at least a few samples before updating display
        guard predictionBuffer.count >= 3 else { return }

        // Calculate weighted confidence for each bin type
        var recycleScore: Double = 0
        var compostScore: Double = 0

        for prediction in predictionBuffer {
            switch prediction.bin {
            case .recycle:
                recycleScore += prediction.confidence
            case .compost:
                compostScore += prediction.confidence
            }
        }

        // Determine winning bin and average confidence
        let totalPredictions = Double(predictionBuffer.count)
        let averageRecycleConfidence = recycleScore / totalPredictions
        let averageCompostConfidence = compostScore / totalPredictions

        let winningBin: WasteBin
        let winningConfidence: Double

        if averageRecycleConfidence > averageCompostConfidence {
            winningBin = .recycle
            winningConfidence = averageRecycleConfidence
        } else {
            winningBin = .compost
            winningConfidence = averageCompostConfidence
        }

        // Only update if we have sufficient confidence or bin changed significantly
        let shouldUpdate = winningConfidence >= stabilityThreshold ||
                          winningBin != predictedBin ||
                          predictionBuffer.count == bufferSize

        if shouldUpdate {
            self.predictedBin = winningBin
            self.confidence = winningConfidence
        }
    }

    // MARK: - Fallback: Color-based Heuristic (Legacy)
    nonisolated private func classifyWithColorHeuristic(pixelBuffer: CVPixelBuffer) {
        guard let color = averageColor(from: pixelBuffer) else {
            Task { @MainActor in
                self.updateRollingAverage(newBin: .recycle, newConfidence: 0.0)
            }
            return
        }

        // Simple heuristic based on dominant color channel
        // Green -> Compost (organic), Blue -> Recycle
        let bin: WasteBin
        if color.green > color.blue {
            bin = .compost
        } else {
            bin = .recycle
        }

        let confidence = Double(max(color.green, color.blue)) * 0.5  // Scale down to indicate lower confidence

        Task { @MainActor in
            self.updateRollingAverage(newBin: bin, newConfidence: confidence)
        }
    }

    nonisolated private func averageColor(from buffer: CVPixelBuffer) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let extent = ciImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: inputExtent
        ]) else { return nil }

        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(outputImage,
                         toBitmap: &bitmap,
                         rowBytes: 4,
                         bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                         format: .RGBA8,
                         colorSpace: CGColorSpaceCreateDeviceRGB())

        let red = CGFloat(bitmap[0]) / 255.0
        let green = CGFloat(bitmap[1]) / 255.0
        let blue = CGFloat(bitmap[2]) / 255.0
        return (red, green, blue)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate Conformance
extension WasteClassifierService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Use Vision ML model if available, otherwise fall back to color detection
        // Access main-actor property safely
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            if let request = self.classificationRequest {
                self.classifyWithVision(pixelBuffer: pixelBuffer, request: request)
            } else {
                self.classifyWithColorHeuristic(pixelBuffer: pixelBuffer)
            }
        }
    }
}

// MARK: - Helper Extensions
extension WasteClassifierService {
    /// Returns a user-friendly description of the current model state
    var modelStateDescription: String {
        switch modelState {
        case .notLoaded:
            return "Model not loaded"
        case .loading:
            return "Loading model..."
        case .ready:
            return "Model ready"
        case .failed(let error):
            return "Model failed: \(error.localizedDescription)"
        }
    }

    /// Returns whether the model is ready for predictions
    var isModelReady: Bool {
        if case .ready = modelState {
            return true
        }
        return false
    }
}
