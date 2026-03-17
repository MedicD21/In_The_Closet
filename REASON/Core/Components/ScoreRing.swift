import SwiftUI

/// Canvas-drawn arc with angularGradient color sweep along the arc path.
/// `ringProgress` animates from 0 to `score/100` using `.easeOut(duration: 1.1)`.
struct ScoreRing: View {
    let score: Int
    let size: CGFloat
    let lineWidth: CGFloat
    let accentColor: Color
    let subtitle: String?

    @State private var ringProgress: CGFloat = 0

    init(score: Int, size: CGFloat = 200, lineWidth: CGFloat = 10,
         accentColor: Color = BrandColor.gold, subtitle: String? = nil) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
        self.accentColor = accentColor
        self.subtitle = subtitle
    }

    var body: some View {
        ZStack {
            Canvas { ctx, sz in
                let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
                let radius = (min(sz.width, sz.height) - lineWidth) / 2
                let startAngle = Angle.degrees(-90)

                // Track arc (full circle)
                var trackPath = Path()
                trackPath.addArc(center: center, radius: radius,
                                 startAngle: startAngle,
                                 endAngle: startAngle + .degrees(360),
                                 clockwise: false)
                ctx.stroke(trackPath, with: .color(BrandColor.textTertiary.opacity(0.2)),
                           style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Score arc (swept up to ringProgress)
                guard ringProgress > 0 else { return }
                let endAngle = startAngle + Angle.degrees(360 * Double(ringProgress))
                var scorePath = Path()
                scorePath.addArc(center: center, radius: radius,
                                 startAngle: startAngle,
                                 endAngle: endAngle,
                                 clockwise: false)

                // angularGradient: color sweeps along the arc
                let gradient = Gradient(colors: [accentColor.opacity(0.5), accentColor])
                ctx.stroke(scorePath,
                           with: .angularGradient(gradient,
                                                  center: center,
                                                  startAngle: startAngle,
                                                  endAngle: endAngle),
                           style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            .frame(width: size, height: size)

            VStack(spacing: 4) {
                if score > 0 {
                    Text("\(score)")
                        .font(size >= 160 ? BrandTypography.score : BrandTypography.scoreSmall)
                        .foregroundColor(BrandColor.textPrimary)
                } else {
                    Text("—")
                        .font(BrandTypography.score)
                        .foregroundColor(BrandColor.textTertiary)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(BrandTypography.micro)
                        .foregroundColor(BrandColor.textSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                ringProgress = CGFloat(score) / 100
            }
        }
    }
}
