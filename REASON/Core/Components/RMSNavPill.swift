import SwiftUI

enum RMSTab: CaseIterable {
    case home, projects, staging, settings

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .projects: return "square.stack.3d.up.fill"
        case .staging:  return "sparkles.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var inactiveIcon: String {
        switch self {
        case .home:     return "house"
        case .projects: return "square.stack.3d.up"
        case .staging:  return "sparkles"
        case .settings: return "gearshape"
        }
    }
}

struct RMSNavPill: View {
    @Binding var selectedTab: RMSTab
    let onFABTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.projects)

            // FAB slot — floats 16pt above pill center
            Button(action: onFABTap) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BrandColor.gold, BrandColor.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: BrandColor.teal.opacity(0.4), radius: 20, x: 0, y: 8)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(BrandColor.background)
                }
            }
            .buttonStyle(FABPressStyle())
            .offset(y: -16)
            .padding(.horizontal, 12)

            tabButton(.staging)
            tabButton(.settings)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(BrandColor.surface.opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(BrandColor.stroke, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func tabButton(_ tab: RMSTab) -> some View {
        let isActive = selectedTab == tab
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { selectedTab = tab }
        } label: {
            Image(systemName: isActive ? tab.icon : tab.inactiveIcon)
                .font(.system(size: 20))
                .foregroundColor(isActive ? BrandColor.teal : BrandColor.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
        }
    }
}
