//
//  ReportGeneratorService.swift
//  Eco Hero
//
//  Generates shareable impact reports as PDFs and images.
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI
import PDFKit
import Observation

enum ReportPeriod: String, CaseIterable, Identifiable {
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
    case allTime = "All Time"

    var id: String { rawValue }

    var dateRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current

        switch self {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (start, now)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (start, now)
        case .allTime:
            return (Date.distantPast, now)
        }
    }
}

struct ImpactStats {
    let carbonSavedKg: Double
    let waterSavedLiters: Double
    let plasticSavedItems: Int
    let activitiesLogged: Int
    let currentStreak: Int
    let currentLevel: Int
    let achievementsUnlocked: Int
    let period: ReportPeriod
}

@Observable
final class ReportGeneratorService {

    /// Generate a PDF report for a user
    @MainActor
    func generatePDF(for profile: UserProfile, period: ReportPeriod) async -> URL? {
        let stats = ImpactStats(
            carbonSavedKg: profile.totalCarbonSavedKg,
            waterSavedLiters: profile.totalWaterSavedLiters,
            plasticSavedItems: profile.totalPlasticSavedItems,
            activitiesLogged: profile.totalActivitiesLogged,
            currentStreak: profile.streak,
            currentLevel: profile.currentLevel,
            achievementsUnlocked: 0, // Would need to query achievements
            period: period
        )

        // Create the report view
        let reportView = ImpactReportView(stats: stats, userName: profile.displayName)

        // Render to PDF
        let renderer = ImageRenderer(content: reportView.frame(width: 612, height: 792))
        renderer.scale = 2.0 // Higher resolution

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("EcoHero_Report_\(UUID().uuidString).pdf")

        // Use ImageRenderer's PDF rendering
        if let consumer = CGDataConsumer(url: tempURL as CFURL) {
            var mediaBox = CGRect(origin: .zero, size: CGSize(width: 612, height: 792))
            if let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) {
                context.beginPDFPage(nil)
                renderer.render { size, render in
                    render(context)
                }
                context.endPDFPage()
                context.closePDF()
                return tempURL
            }
        }

        return nil
    }

    /// Generate a shareable image with impact summary
    @MainActor
    func generateShareImage(for profile: UserProfile) -> UIImage? {
        let stats = ImpactStats(
            carbonSavedKg: profile.totalCarbonSavedKg,
            waterSavedLiters: profile.totalWaterSavedLiters,
            plasticSavedItems: profile.totalPlasticSavedItems,
            activitiesLogged: profile.totalActivitiesLogged,
            currentStreak: profile.streak,
            currentLevel: profile.currentLevel,
            achievementsUnlocked: 0,
            period: .allTime
        )

        let shareCard = ShareCardView(stats: stats, userName: profile.displayName)

        let renderer = ImageRenderer(content: shareCard.frame(width: 400, height: 500))
        renderer.scale = 3.0 // High resolution for sharing

        return renderer.uiImage
    }

    /// Generate share text for social media
    func generateShareText(for profile: UserProfile) -> String {
        let carbonText = String(format: "%.1f", profile.totalCarbonSavedKg)
        let waterText = String(format: "%.0f", profile.totalWaterSavedLiters)

        return """
        🌍 My Eco Hero Impact 🌱

        🌿 \(carbonText) kg CO₂ saved
        💧 \(waterText) L water conserved
        ♻️ \(profile.totalPlasticSavedItems) plastic items avoided
        🔥 \(profile.streak) day streak
        ⭐️ Level \(profile.currentLevel)

        Join me in making a difference! #EcoHero #Sustainability
        """
    }
}

// MARK: - Share Card View (for image generation)

struct ShareCardView: View {
    let stats: ImpactStats
    let userName: String

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Eco Hero")
                    .font(.title.bold())

                Text(userName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Stats grid
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    shareStatBox(
                        value: String(format: "%.1f kg", stats.carbonSavedKg),
                        label: "CO₂ Saved",
                        icon: "cloud.fill",
                        color: .blue
                    )
                    shareStatBox(
                        value: String(format: "%.0f L", stats.waterSavedLiters),
                        label: "Water Saved",
                        icon: "drop.fill",
                        color: .cyan
                    )
                }

                HStack(spacing: 20) {
                    shareStatBox(
                        value: "\(stats.plasticSavedItems)",
                        label: "Plastic Avoided",
                        icon: "bag.fill",
                        color: .orange
                    )
                    shareStatBox(
                        value: "\(stats.currentStreak) days",
                        label: "Streak",
                        icon: "flame.fill",
                        color: .red
                    )
                }
            }

            // Level badge
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Level \(stats.currentLevel)")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.yellow.opacity(0.2), in: Capsule())

            // Footer
            Text("#EcoHero")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .background(Color.white)
    }

    private func shareStatBox(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
