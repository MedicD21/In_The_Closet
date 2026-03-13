import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            BrandBackground()

            switch appModel.rootDestination {
            case .splash:
                SplashView()
            case .onboarding:
                OnboardingView()
            case .auth:
                AuthView()
            case .main:
                MainTabView()
            }
        }
        .preferredColorScheme(themeStore.preferredColorScheme)
        .task {
            await appModel.bootstrap()
        }
        .animation(.easeInOut(duration: 0.35), value: appModel.rootDestination)
        .alert(item: $appModel.notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
