import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            switch appModel.rootDestination {
            case .splash:
                SplashView()
            case .onboarding:
                OnboardingView()
            case .auth:
                AuthView()
            case .main:
                RMSShellView(container: appModel.container, appModel: appModel)
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
