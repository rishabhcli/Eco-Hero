//
//  LearnView.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import SwiftUI

struct LearnView: View {
    var embedInNavigation: Bool = true
    @Environment(TipModelService.self) private var tipModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCategory: ActivityCategory = .meals
    @State private var smartTip: String?
    @State private var factOfDay: String = AppConstants.EducationalFacts.randomFact()
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false

    var body: some View {
        Group {
            if embedInNavigation {
                NavigationStack {
                    content
                        .navigationTitle("Learn")
                }
            } else {
                content
            }
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                dailyFactCard
                    .offset(y: scrollOffset * 0.2)
                    .bounceIn(delay: 0.1)

                tipsSection
                    .bounceIn(delay: 0.2)

                // Apple Intelligence feature - only show on iOS 26+
                if #available(iOS 26, *) {
                    smartTipSection
                        .bounceIn(delay: 0.3)
                }

                allFactsSection
                    .bounceIn(delay: 0.4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .readScrollOffset(into: $scrollOffset)
        }
        .coordinateSpace(name: "scroll")
        .background(
            ZStack {
                Color(.systemGroupedBackground)

                // Bold floating orbs
                FloatingOrbsBackground(
                    orbCount: 6,
                    colors: [
                        Color.green.opacity(0.2),
                        Color(hex: "16A34A").opacity(0.15),
                        Color(hex: "22C55E").opacity(0.12)
                    ]
                )

                // Bold floating leaves ambient effect
                FloatingLeafView(leafCount: 10, colors: [
                    Color(hex: "16A34A"),
                    Color(hex: "22C55E"),
                    Color(hex: "4ADE80")
                ])
                .opacity(0.6)
            }
            .ignoresSafeArea()
        )
    }

    private var dailyFactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "16A34A").opacity(0.2))
                            .frame(width: 32, height: 32)
                            .blur(radius: 4)

                        Image(systemName: "globe.americas.fill")
                            .font(.body)
                            .foregroundStyle(Color(hex: "16A34A"))
                            .symbolEffect(.bounce, value: isRefreshing)
                    }

                    Text("Eco Fact of the Day")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "16A34A"))
                }
                Spacer()
                Group {
                    if #available(iOS 26, *) {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isRefreshing.toggle()
                                factOfDay = AppConstants.EducationalFacts.randomFact()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: "16A34A"))
                                .padding(8)
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        }
                        .buttonStyle(.glass(.regular.tint(Color(hex: "16A34A").opacity(0.3)).interactive()))
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isRefreshing.toggle()
                                factOfDay = AppConstants.EducationalFacts.randomFact()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: "16A34A"))
                                .padding(8)
                                .background(Color(hex: "16A34A").opacity(0.15), in: Circle())
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        }
                    }
                }
            }

            Text(factOfDay)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(hex: "16A34A").opacity(0.25), Color(hex: "16A34A").opacity(0.15)]
                                : [Color(hex: "DCFCE7"), Color(hex: "D1FAE5")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle inner glow - adjust opacity for dark mode
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: "16A34A").opacity(colorScheme == .dark ? 0.4 : 0.2), lineWidth: 1)
            }
        )
        .shadow(color: Color(hex: "16A34A").opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 8, x: 0, y: 4)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topics")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(ActivityCategory.allCases.enumerated()), id: \.element) { index, category in
                    EnhancedCategoryTipCard(category: category, index: index)
                }
            }
        }
    }

    @available(iOS 26, *)
    private var smartTipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Tip Generator", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "2563EB"))
                Spacer()
                if tipModel.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ActivityCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(category.rawValue)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                        }
                        .buttonStyle(.glass(
                            selectedCategory == category
                                ? .regular.tint(Color(hex: "2563EB").opacity(0.8)).interactive()
                                : .regular.tint(.gray.opacity(0.2)).interactive()
                        ))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if tipModel.isGenerating && !tipModel.streamedTip.isEmpty {
                    Text(tipModel.streamedTip)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } else if let tip = smartTip, !tip.isEmpty {
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } else {
                    Text("Tap Generate to get an AI-powered sustainability tip.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .frame(minHeight: 60)

            Button(action: generateSmartTip) {
                Label(
                    tipModel.isGenerating ? "Generating..." : "Generate Tip",
                    systemImage: tipModel.isGenerating ? "ellipsis" : "sparkles"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
            }
            .buttonStyle(.glass(.regular.tint(Color(hex: "2563EB").opacity(0.9)).interactive()))
            .disabled(tipModel.isGenerating)
            .opacity(tipModel.isGenerating ? 0.7 : 1.0)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            if smartTip == nil {
                smartTip = tipModel.generateTip(for: selectedCategory)
            }
        }
    }

    private var allFactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Eco Knowledge")
                    .font(.headline)
                Spacer()
                Text("\(AppConstants.EducationalFacts.facts.count) facts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVStack(spacing: 10) {
                ForEach(Array(AppConstants.EducationalFacts.facts.enumerated()), id: \.offset) { index, fact in
                    EnhancedFactCard(fact: fact, number: index + 1, index: index)
                }
            }
        }
    }

    private func generateSmartTip() {
        Task {
            await tipModel.generateStreamingTip(for: selectedCategory)
            smartTip = tipModel.streamedTip
        }
    }
}


struct CategoryTipCard: View {
    let category: ActivityCategory

    var body: some View {
        NavigationLink(destination: CategoryTipsDetailView(category: category)) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundStyle(category.color)
                    .padding(10)
                    .background(category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                Text(category.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("Learn more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct EnhancedCategoryTipCard: View {
    let category: ActivityCategory
    let index: Int
    @Namespace private var glassNamespace

    @State private var isVisible = false
    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        NavigationLink(destination: CategoryTipsDetailView(category: category)) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    // Glow behind icon
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                        .scaleEffect(isHovered ? 1.3 : 1.0)

                    Image(systemName: category.icon)
                        .font(.body)
                        .foregroundStyle(category.color)
                        .padding(10)
                        .background(category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                        .symbolEffect(.bounce, value: isVisible)
                }

                Text(category.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("Learn more")
                        .font(.caption)
                        .foregroundStyle(category.color)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(category.color)
                        .offset(x: isHovered ? 3 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .modifier(CategoryCardStyleModifier(category: category, isPressed: isPressed, glassNamespace: glassNamespace))
        .scaleEffect(isPressed ? 0.97 : 1)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08)) {
                isVisible = true
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct FactCard: View {
    let fact: String
    let number: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "16A34A"))
                .frame(width: 24, height: 24)
                .background(
                    colorScheme == .dark
                        ? Color(hex: "16A34A").opacity(0.3)
                        : Color(hex: "DCFCE7"),
                    in: Circle()
                )

            Text(fact)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct EnhancedFactCard: View {
    let fact: String
    let number: Int
    let index: Int
    @Environment(\.colorScheme) private var colorScheme

    @State private var isVisible = false
    @State private var isExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                // Glow behind number
                Circle()
                    .fill(Color(hex: "16A34A").opacity(colorScheme == .dark ? 0.3 : 0.2))
                    .frame(width: 32, height: 32)
                    .blur(radius: 6)

                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "16A34A"))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(hex: "16A34A").opacity(0.35), Color(hex: "16A34A").opacity(0.25)]
                                        : [Color(hex: "DCFCE7"), Color(hex: "BBF7D0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fact)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(isExpanded ? nil : 2)

                if fact.count > 80 {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(isExpanded ? "Show less" : "Read more")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "16A34A"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                    .modifier(ReadMoreButtonStyleModifier())
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .popCard(cornerRadius: 14, background: Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "16A34A").opacity(0.1), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -15)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                isVisible = true
            }
        }
    }
}

private struct CategoryCardStyleModifier: ViewModifier {
    let category: ActivityCategory
    let isPressed: Bool
    let glassNamespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.6))
                )
                .glassEffect(
                    .regular.tint(category.color.opacity(0.1)).interactive(),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .glassEffectID("category-\(category.rawValue)", in: glassNamespace)
        } else {
            content
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .shadow(color: isPressed ? category.color.opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
                )
        }
    }
}

private struct ReadMoreButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(.glass(.regular.tint(Color(hex: "16A34A").opacity(0.2)).interactive()))
        } else {
            content
                .background(Color(hex: "16A34A").opacity(0.1), in: Capsule())
        }
    }
}

struct CategoryTipsDetailView: View {
    let category: ActivityCategory
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(category.color)
                        .padding(16)
                        .background(category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))

                    Text(category.rawValue)
                        .font(.title.bold())

                    Text("Tips and information about \(category.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Main tip
                if let tip = AppConstants.EcoTips.tip(for: category) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tip.title)
                            .font(.headline)
                        Text(tip.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
                }

                // Facts section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Did you know?")
                        .font(.headline)

                    ForEach(Array(AppConstants.EducationalFacts.facts.prefix(3).enumerated()), id: \.offset) { _, fact in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "F59E0B"))
                                .padding(6)
                                .background(
                                    colorScheme == .dark
                                        ? Color(hex: "F59E0B").opacity(0.2)
                                        : Color(hex: "FEF3C7"),
                                    in: Circle()
                                )
                            Text(fact)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .padding(14)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LearnView()
        .environment(TipModelService())
}

#Preview("Category Detail") {
    NavigationStack {
        CategoryTipsDetailView(category: .meals)
    }
}
