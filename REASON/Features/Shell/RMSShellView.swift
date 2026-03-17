import SwiftUI

struct RMSShellView: View {
    let container: AppContainer
    @ObservedObject var appModel: AppModel

    @State private var selectedTab: RMSTab = .home
    @State private var isShowingUpload = false
    @State private var uploadDraft = UploadDraft()

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .ignoresSafeArea(edges: .top)

            RMSNavPill(selectedTab: $selectedTab, onFABTap: { isShowingUpload = true })
                .padding(.bottom, 24)
        }
        .background(BrandColor.background.ignoresSafeArea())
        .sheet(isPresented: $isShowingUpload) {
            UploadFlowContainerView(
                container: container,
                appModel: appModel,
                currentUser: appModel.currentUser,
                initialDraft: uploadDraft,
                onDismiss: { isShowingUpload = false }
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(
                appModel: appModel,
                onStartUpload: { draft in uploadDraft = draft; isShowingUpload = true },
                onNavigateToProjects: { withAnimation { selectedTab = .projects } },
                onNavigateToSettings: { withAnimation { selectedTab = .settings } }
            )
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 4)), removal: .opacity))
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
        case .projects:
            ProjectsView(appModel: appModel, container: container)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 4)), removal: .opacity))
                .animation(.easeInOut(duration: 0.22), value: selectedTab)
        case .staging:
            StagingHubView(
                appModel: appModel,
                onStartUpload: { draft in uploadDraft = draft; isShowingUpload = true }
            )
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 4)), removal: .opacity))
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
        case .settings:
            SettingsView(appModel: appModel, themeStore: container.themeStore)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 4)), removal: .opacity))
                .animation(.easeInOut(duration: 0.22), value: selectedTab)
        }
    }
}
