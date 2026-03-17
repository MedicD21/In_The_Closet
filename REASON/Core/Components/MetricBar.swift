import SwiftUI

struct MetricBar: View {
    let label: String
    let value: Int        // 0–100
    let index: Int        // for stagger delay

    @State private var progress: CGFloat = 0

    private var barColor: Color {
        if value < 40  { return BrandColor.coral }
        if value < 70  { return BrandColor.gold }
        return BrandColor.teal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(BrandTypography.label)
                    .foregroundColor(BrandColor.textSecondary)
                Spacer()
                Text("\(value)")
                    .font(BrandTypography.label)
                    .foregroundColor(barColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BrandColor.surface)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7).delay(Double(index) * 0.05)) {
                progress = CGFloat(value) / 100
            }
        }
    }
}
