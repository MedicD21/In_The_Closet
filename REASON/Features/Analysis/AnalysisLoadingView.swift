import SwiftUI

struct AnalysisLoadingView: View {
    let mode: ProjectMode
    @State private var messageIndex = 0

    private var messages: [String] {
        switch mode {
        case .organize:
            [
                "Reviewing your space...",
                "Finding simple ways to make it work better...",
                "Building your reset plan..."
            ]
        case .stageForSelling:
            [
                "Reading the room like a future buyer might...",
                "Finding the easiest staging wins...",
                "Building a calmer showing-day plan..."
            ]
        case .compareProgress:
            [
                "Comparing what improved...",
                "Measuring the strongest gains...",
                "Highlighting the next best moves..."
            ]
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ProgressView()
                .scaleEffect(1.4)
                .tint(BrandColor.teal)

            Text(messages[messageIndex])
                .font(BrandTypography.screenTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("Reset My Space keeps the tone warm, practical, and focused on the easiest helpful changes first.")
                .font(BrandTypography.body)
                .foregroundStyle(BrandColor.secondaryText(for: .light))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
        .task {
            while true {
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeInOut) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }
}
