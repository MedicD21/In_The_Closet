import SwiftUI

enum TagChipVariant {
    case filled
    case outlined
}

struct TagChip: View {
    let title: String
    let accent: Color
    var variant: TagChipVariant = .outlined

    var body: some View {
        Text(title)
            .font(BrandTypography.micro)
            .foregroundColor(accent)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(variant == .filled ? accent.opacity(0.18) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(variant == .outlined ? accent : Color.clear, lineWidth: 1)
            )
    }
}
