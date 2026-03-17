import SwiftUI

private struct OnboardingPage {
    let symbol: String
    let accent: Color
    let headline: String
    let subtext: String
    let glowColor: Color
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        symbol: "camera.viewfinder",
        accent: BrandColor.teal,
        headline: "Capture Your Space",
        subtext: "Take a photo and let AI score every corner.",
        glowColor: BrandColor.tealMuted
    ),
    OnboardingPage(
        symbol: "chart.bar.doc.horizontal",
        accent: BrandColor.gold,
        headline: "See What's Holding You Back",
        subtext: "Get a room-by-room breakdown with an actionable reset plan.",
        glowColor: BrandColor.goldMuted
    ),
    OnboardingPage(
        symbol: "sparkles.rectangle.stack",
        accent: BrandColor.coral,
        headline: "Transform Any Space",
        subtext: "From cluttered to listed — organize, stage, or compare your progress.",
        glowColor: BrandColor.coral.opacity(0.15)
    ),
]

struct OnboardingView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(onboardingPages.indices, id: \.self) { i in
                    pageView(for: onboardingPages[i], isLast: i == onboardingPages.count - 1)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            bottomControls
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
        .background(BrandColor.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func pageView(for page: OnboardingPage, isLast: Bool) -> some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            RadialGradient(
                colors: [page.glowColor, .clear],
                center: .top,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(page.accent.opacity(0.18))
                        .frame(width: 120, height: 120)
                    Image(systemName: page.symbol)
                        .font(.system(size: 52))
                        .foregroundColor(page.accent)
                }

                VStack(spacing: 12) {
                    Text(page.headline)
                        .font(BrandTypography.displayTitle)
                        .foregroundColor(BrandColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(page.subtext)
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                if isLast {
                    ZStack {
                        Image("OnboardingHomePreview")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 280)
                            .blur(radius: 4)
                            .clipped()
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .frame(width: 160, height: 280)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(BrandColor.stroke, lineWidth: 0.5)
                    )
                }

                Spacer()
                Spacer()
            }
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(onboardingPages.indices, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? BrandColor.teal : BrandColor.textTertiary)
                        .frame(
                            width: i == currentPage ? 8 : 6,
                            height: i == currentPage ? 8 : 6
                        )
                        .animation(.spring(response: 0.4), value: currentPage)
                }
            }

            if currentPage < onboardingPages.count - 1 {
                PrimaryButton("Continue") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                }
            } else {
                PrimaryButton("Get Started") {
                    appModel.completeOnboarding()
                }

                GhostButton(title: "Already have an account? Sign in") {
                    appModel.completeOnboarding()
                }
            }
        }
    }
}
