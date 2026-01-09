//
//  WasteSortingView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import SwiftData

struct WasteSortingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WasteClassifierService.self) private var classifier
    @Environment(AuthenticationManager.self) private var authManager
    @Query(sort: [SortDescriptor(\WasteSortingResult.timestamp, order: .reverse)], animation: .snappy)
    private var recentResults: [WasteSortingResult]

    @State private var score: Int = 0
    @State private var streak: Int = 0
    @State private var feedbackText: String?
    @State private var showPermissionAlert = false
    @State private var lastResultCorrect: Bool?
    @State private var showFlash: Bool = false
    @Namespace private var glassNamespace

    private let impactGenerator = UINotificationFeedbackGenerator()

    var body: some View {
        ZStack {
            // Full-screen camera background
            CameraPreviewView(session: classifier.session)
                .ignoresSafeArea()

            // Subtle vignette overlay
            RadialGradient(
                colors: [.clear, .black.opacity(0.4)],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Flash effect on selection
            if showFlash {
                Rectangle()
                    .fill(lastResultCorrect == true ? Color.green.opacity(0.25) : Color.red.opacity(0.25))
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Main content with Liquid Glass
            GlassEffectContainer(spacing: 30) {
                VStack(spacing: 0) {
                    // Top stats bar with Liquid Glass
                    topStatsBar
                        .padding(.top, 60)
                        .padding(.horizontal, 20)

                    Spacer()

                    // Center prediction display with Liquid Glass
                    predictionOverlay
                        .padding(.bottom, 30)

                    // Bottom controls area
                    VStack(spacing: 16) {
                        if feedbackText != nil {
                            feedbackBanner
                        }

                        binButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Vision Sorter")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .alert("Camera Access Needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enable camera access in Settings to play the sorting game.")
        }
        .onAppear {
            Task { await handleAuthorization() }
        }
        .onDisappear {
            classifier.stopSession()
        }
    }

    private var topStatsBar: some View {
        HStack(spacing: 12) {
            statBadge(title: "Score", value: "\(score)", icon: "star.fill", color: .yellow)
                .compatibleGlassEffectID("stat-score", in: glassNamespace)
            statBadge(title: "Streak", value: "\(streak)", icon: "flame.fill", color: .orange)
                .compatibleGlassEffectID("stat-streak", in: glassNamespace)
            statBadge(title: "Accuracy", value: "\(accuracyString)%", icon: "target", color: .green)
                .compatibleGlassEffectID("stat-accuracy", in: glassNamespace)
        }
        .compatibleGlassEffectUnion(id: "stats", namespace: glassNamespace)
    }

    private func statBadge(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var predictionOverlay: some View {
        VStack(spacing: 16) {
            // Scanning indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green, radius: 6)
                    .modifier(PulsingModifier())

                Text("ANALYZING")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(3)
            }

            // Main prediction
            VStack(spacing: 12) {
                Image(systemName: classifier.predictedBin.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(classifier.predictedBin.color)
                    .shadow(color: classifier.predictedBin.color.opacity(0.6), radius: 12)
                    .contentTransition(.symbolEffect(.replace))

                Text(classifier.predictedBin.rawValue.uppercased())
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Confidence meter
                confidenceMeter
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 36)
        .compatibleGlassEffect(
            tintColor: classifier.predictedBin.color.opacity(0.2),
            cornerRadius: 32,
            interactive: true
        )
        .compatibleGlassEffectID("prediction", in: glassNamespace)
    }

    private var confidenceMeter: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [classifier.predictedBin.color.opacity(0.7), classifier.predictedBin.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * classifier.confidence, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: classifier.confidence)
                }
            }
            .frame(height: 8)
            .frame(width: 200)

            Text("\(Int(classifier.confidence * 100))% confidence")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var feedbackBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: lastResultCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(lastResultCorrect == true ? .green : .red)
                .contentTransition(.symbolEffect(.replace))

            Text(feedbackText ?? "")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .compatibleGlassEffect(
            tintColor: (lastResultCorrect == true ? Color.green : Color.red).opacity(0.4),
            cornerRadius: 20,
            interactive: false
        )
        .compatibleGlassEffectID("feedback", in: glassNamespace)
        .compatibleGlassEffectTransition()
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private var binButtons: some View {
        HStack(spacing: 12) {
            ForEach(WasteBin.allCases, id: \.self) { bin in
                let isPredicted = classifier.predictedBin == bin
                let confidenceGlow = isPredicted ? classifier.confidence : 0

                if #available(iOS 26, *) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            evaluateSelection(bin)
                        }
                        UIImpactFeedbackGenerator(style: isPredicted ? .medium : .light).impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: bin.icon)
                                .font(.system(size: isPredicted ? 22 : 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: isPredicted)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPredicted)

                            Text(bin.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)

                            // Confidence indicator for predicted bin
                            if isPredicted && classifier.confidence > 0.3 {
                                Text("\(Int(classifier.confidence * 100))%")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isPredicted ? 12 : 10)
                    }
                    .buttonStyle(.glass(
                        isPredicted
                            ? .regular.tint(bin.color.opacity(0.7 + confidenceGlow * 0.3)).interactive()
                            : .regular.tint(bin.color.opacity(0.4)).interactive()
                    ))
                    .glassEffectID("bin-\(bin.rawValue)", in: glassNamespace)
                    .scaleEffect(isPredicted ? 1.05 : 1.0)
                    .shadow(
                        color: isPredicted ? bin.color.opacity(0.5 + confidenceGlow * 0.3) : .clear,
                        radius: isPredicted ? 12 + confidenceGlow * 8 : 0,
                        x: 0,
                        y: isPredicted ? 4 : 0
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPredicted)
                } else {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            evaluateSelection(bin)
                        }
                        UIImpactFeedbackGenerator(style: isPredicted ? .medium : .light).impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: bin.icon)
                                .font(.system(size: isPredicted ? 22 : 18, weight: .semibold))
                                .foregroundStyle(.white)

                            Text(bin.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)

                            // Confidence indicator for predicted bin
                            if isPredicted && classifier.confidence > 0.3 {
                                Text("\(Int(classifier.confidence * 100))%")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isPredicted ? 12 : 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(bin.color.opacity(isPredicted ? 0.6 + confidenceGlow * 0.2 : 0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(isPredicted ? 0.5 : 0.3), lineWidth: isPredicted ? 2 : 1)
                                )
                        )
                        .shadow(
                            color: bin.color.opacity(isPredicted ? 0.5 + confidenceGlow * 0.3 : 0.4),
                            radius: isPredicted ? 12 : 8,
                            x: 0,
                            y: isPredicted ? 4 : 3
                        )
                        .scaleEffect(isPredicted ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPredicted)
                }
            }
        }
    }

    private var recentHistoryCompact: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            ForEach(recentResults.prefix(10)) { result in
                Circle()
                    .fill(result.isCorrect ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: result.isCorrect ? .green.opacity(0.6) : .red.opacity(0.6), radius: 4)
            }

            if recentResults.isEmpty {
                Text("No attempts yet")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .compatibleGlassEffect(shape: Capsule(), interactive: false)
        .compatibleGlassEffectID("history", in: glassNamespace)
    }

    private func evaluateSelection(_ bin: WasteBin) {
        let predicted = classifier.predictedBin
        let correct = predicted == bin
        let points = correct ? 10 : -5

        // Ensure score doesn't go below 0
        score = max(0, score + points)
        streak = correct ? streak + 1 : 0
        lastResultCorrect = correct

        withAnimation(.easeInOut(duration: 0.12)) {
            showFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.15)) {
                showFlash = false
            }
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            feedbackText = correct
                ? "Perfect! \(bin.rawValue) is correct."
                : "Not quite! That's \(predicted.rawValue)."
        }

        // Auto-dismiss feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                feedbackText = nil
            }
        }

        impactGenerator.notificationOccurred(correct ? .success : .error)

        let result = WasteSortingResult(predictedBin: predicted,
                                        userSelection: bin,
                                        isCorrect: correct,
                                        confidence: classifier.confidence,
                                        pointsAwarded: points)
        modelContext.insert(result)
        do {
            try modelContext.save()
        } catch {
            print("⚠️ WasteSorting: Failed to save result: \(error.localizedDescription)")
        }
    }

    private var accuracyString: String {
        let total = recentResults.count
        let correct = recentResults.filter { $0.isCorrect }.count
        guard total > 0 else { return "0" }
        return String(Int((Double(correct) / Double(total)) * 100))
    }

    private func handleAuthorization() async {
        if classifier.authorizationState == .unknown {
            await classifier.requestAuthorization()
        }

        await MainActor.run {
            switch classifier.authorizationState {
            case .allowed:
                classifier.startSession()
            case .denied:
                showPermissionAlert = true
            case .unknown:
                break
            }
        }
    }
}


// MARK: - Recent History Compact View

private struct RecentHistoryCompact: View {
    let results: [WasteSortingResult]
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            ForEach(results.prefix(10)) { result in
                Circle()
                    .fill(result.isCorrect ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: result.isCorrect ? .green.opacity(0.6) : .red.opacity(0.6), radius: 4)
            }

            if results.isEmpty {
                Text("No attempts yet")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .compatibleGlassEffect(shape: Capsule(), interactive: false)
        .compatibleGlassEffectID("history", in: namespace)
    }
}

// MARK: - Pulsing Animation Modifier
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

#Preview {
    NavigationStack {
        WasteSortingView()
            .environment(AuthenticationManager())
            .environment(WasteClassifierService())
            .modelContainer(for: WasteSortingResult.self, inMemory: true)
    }
}
