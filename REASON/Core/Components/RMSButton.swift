import SwiftUI

// MARK: — Primary
struct PrimaryButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    init(_ title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTypography.button)
                .foregroundColor(isDisabled ? BrandColor.textTertiary : BrandColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isDisabled ? BrandColor.surfaceElevated : BrandColor.teal)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled)
    }
}

// MARK: — Secondary
struct SecondaryButton: View {
    let title: String
    let accent: Color
    let action: () -> Void

    init(_ title: String, accent: Color = BrandColor.teal, action: @escaping () -> Void) {
        self.title = title
        self.accent = accent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTypography.button)
                .foregroundColor(accent)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent, lineWidth: 1)
                )
        }
    }
}

// MARK: — Ghost
struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTypography.button)
                .foregroundColor(BrandColor.teal)
        }
    }
}

// MARK: — Destructive
struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTypography.button)
                .foregroundColor(BrandColor.coral)
        }
    }
}

// MARK: — FAB press style
struct FABPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: — Budget card press style
struct BudgetCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}
