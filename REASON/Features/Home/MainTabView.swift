import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                ProjectsView()
            }
            .tabItem {
                Label("Projects", systemImage: "square.stack.3d.up")
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
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(BrandColor.teal)
    }
}
