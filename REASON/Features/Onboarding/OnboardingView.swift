import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @State private var page = 0

    private let steps = [
        OnboardingStep(
            title: "Upload one space",
            detail: "Start with a pantry, closet, drawer, bathroom, garage, or a custom corner that needs a fresh plan.",
            imageName: "camera.viewfinder",
            accent: BrandColor.teal
        ),
        OnboardingStep(
            title: "Get a supportive score",
            detail: "Reset My Space explains what is working, what feels harder than it should, and where the easiest wins live.",
            imageName: "chart.bar.doc.horizontal",
            accent: BrandColor.gold
        ),
        OnboardingStep(
            title: "Reset with confidence",
            detail: "See budget-minded Amazon suggestions, staged concept previews, and track progress over time.",
            imageName: "sparkles.rectangle.stack",
            accent: BrandColor.plum
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            VStack(spacing: 12) {
                TagChip(title: "Fresh, guided, and budget-aware", accent: BrandColor.gold)
                Text("Reset My Space")
                    .font(BrandTypography.brandTitle)
                    .foregroundStyle(colorScheme == .dark ? BrandColor.gold : BrandColor.teal)
                Text("By REASON")
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                Text("Warm guidance for organizing, staging, and finding your space again.")
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            TabView(selection: $page) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    BrandCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: step.imageName)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(step.accent)
                                    .frame(width: 72, height: 72)
                                    .background(step.accent.opacity(0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                Spacer()
                                Text("0\(index + 1)")
                                    .font(BrandTypography.caption)
                                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                            }

                            Text(step.title)
                                .font(BrandTypography.screenTitle)
                                .foregroundStyle(BrandColor.primaryText(for: colorScheme))

                            Text(step.detail)
                                .font(BrandTypography.body)
                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 450)

            PrimaryActionButton(page == steps.count - 1 ? "Get Started" : "Next") {
                if page == steps.count - 1 {
                    appModel.completeOnboarding()
                } else {
                    withAnimation(.easeInOut) {
                        page += 1
                    }
                }
            }
            .padding(.horizontal, 24)

            SecondaryActionButton(title: "Already have an account? Sign in") {
                appModel.completeOnboarding()
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
    }
}

private struct OnboardingStep {
    let title: String
    let detail: String
    let imageName: String
    let accent: Color
}
