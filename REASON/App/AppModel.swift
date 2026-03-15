import SwiftUI

enum RootDestination {
    case splash
    case onboarding
    case auth
    case main
}

@MainActor
final class AppModel: ObservableObject {
    @Published var rootDestination: RootDestination = .splash
    @Published var currentUser: UserProfile?
    @Published var projects: [SpaceProject] = []
    @Published var notice: AppNotice?

    let container: AppContainer

    private let onboardingKey = "reason.onboarding.completed"
    private var hasBootstrapped = false

    init(container: AppContainer) {
        self.container = container
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        AppConsole.app.notice("bootstrap started")

        try? await Task.sleep(for: .milliseconds(900))

        currentUser = await container.authService.restoreSession()
        if let currentUser {
            AppConsole.auth.notice("restored session for user=\(currentUser.email, privacy: .public)")
            await loadProjects(for: currentUser.id)
            rootDestination = .main
            AppConsole.app.notice("root destination -> main")
            return
        }

        let onboardingCompleted = UserDefaults.standard.bool(forKey: onboardingKey)
        rootDestination = onboardingCompleted ? .auth : .onboarding
        AppConsole.app.notice("root destination -> \(String(describing: self.rootDestination), privacy: .public)")
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        rootDestination = .auth
        AppConsole.app.notice("onboarding completed")
    }

    func signIn(user: UserProfile) async {
        currentUser = user
        AppConsole.auth.notice("signed in user=\(user.email, privacy: .public) method=\(user.authMethod.rawValue, privacy: .public)")
        await loadProjects(for: user.id)
        withAnimation(.easeInOut) {
            rootDestination = .main
        }
        AppConsole.app.notice("root destination -> main")
    }

    func signOut() async {
        do {
            try await container.authService.signOut()
            AppConsole.auth.notice("signed out current user")
            currentUser = nil
            projects = []
            rootDestination = .auth
            AppConsole.app.notice("root destination -> auth")
        } catch {
            AppConsole.auth.error("sign out failed: \(error.localizedDescription, privacy: .public)")
            notice = AppNotice(title: "Couldn't Sign Out", message: error.localizedDescription)
        }
    }

    func deleteAccount() async {
        do {
            try await container.authService.deleteAccount()
            AppConsole.auth.notice("account deleted")
            currentUser = nil
            projects = []
            rootDestination = .auth
        } catch {
            AppConsole.auth.error("delete account failed: \(error.localizedDescription, privacy: .public)")
            notice = AppNotice(title: "Couldn't Delete Account", message: error.localizedDescription)
        }
    }

    func loadProjects(for userID: UUID? = nil) async {
        guard let resolvedUserID = userID ?? currentUser?.id else { return }

        do {
            AppConsole.projects.notice("loading projects for userID=\(resolvedUserID.uuidString, privacy: .public)")
            projects = try await container.projectRepository.fetchProjects(for: resolvedUserID)
            AppConsole.projects.notice("loaded \(self.projects.count, privacy: .public) projects")
        } catch {
            AppConsole.projects.error("load projects failed: \(error.localizedDescription, privacy: .public)")
            notice = AppNotice(title: "Couldn't Load Projects", message: error.localizedDescription)
        }
    }

    func save(project: SpaceProject) async {
        do {
            AppConsole.projects.notice("saving project id=\(project.id.uuidString, privacy: .public) title=\(project.title, privacy: .public)")
            let saved = try await container.projectRepository.save(project: project)
            if let index = projects.firstIndex(where: { $0.id == saved.id }) {
                projects[index] = saved
            } else {
                projects.insert(saved, at: 0)
            }
            projects.sort(by: { $0.updatedAt > $1.updatedAt })
            AppConsole.projects.notice("saved project id=\(saved.id.uuidString, privacy: .public) totalProjects=\(self.projects.count, privacy: .public)")
        } catch {
            AppConsole.projects.error("save project failed: \(error.localizedDescription, privacy: .public)")
            notice = AppNotice(title: "Couldn't Save Project", message: error.localizedDescription)
        }
    }

    func delete(projectID: UUID) async {
        guard let userID = currentUser?.id else { return }

        do {
            AppConsole.projects.notice("deleting project id=\(projectID.uuidString, privacy: .public)")
            try await container.projectRepository.delete(projectID: projectID, for: userID)
            projects.removeAll { $0.id == projectID }
            AppConsole.projects.notice("deleted project id=\(projectID.uuidString, privacy: .public) remaining=\(self.projects.count, privacy: .public)")
        } catch {
            AppConsole.projects.error("delete project failed: \(error.localizedDescription, privacy: .public)")
            notice = AppNotice(title: "Couldn't Delete Project", message: error.localizedDescription)
        }
    }
}
