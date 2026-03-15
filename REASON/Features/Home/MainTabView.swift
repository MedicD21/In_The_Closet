import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                ProjectsView()
            }
            .tabItem {
                Label("Projects", systemImage: "square.stack.3d.up.fill")
            }

            NavigationStack {
                StagingHubView()
            }
            .tabItem {
                Label("Staging", systemImage: "sparkles")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(BrandColor.teal)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(BrandColor.tabBarBackground(for: colorScheme), for: .tabBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .tabBar)
    }
}
