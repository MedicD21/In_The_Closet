import SwiftUI

@main
struct REASONApp: App {
    @StateObject private var appModel = AppModel(container: .bootstrap())

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(appModel)
                .environmentObject(appModel.container.themeStore)
        }
    }
}
