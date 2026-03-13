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

        try? await Task.sleep(for: .milliseconds(900))

        currentUser = await container.authService.restoreSession()
        if let currentUser {
            await loadProjects(for: currentUser.id)
            rootDestination = .main
            return
        }

        let onboardingCompleted = UserDefaults.standard.bool(forKey: onboardingKey)
        rootDestination = onboardingCompleted ? .auth : .onboarding
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        rootDestination = .auth
    }

    func signIn(user: UserProfile) async {
        currentUser = user
        await loadProjects(for: user.id)
        withAnimation(.easeInOut) {
            rootDestination = .main
        }
    }

    func signOut() async {
        do {
            try await container.authService.signOut()
            currentUser = nil
            projects = []
            rootDestination = .auth
        } catch {
            notice = AppNotice(title: "Couldn't Sign Out", message: error.localizedDescription)
        }
    }

    func deleteAccount() async {
        do {
            try await container.authService.deleteAccount()
            currentUser = nil
            projects = []
            rootDestination = .auth
        } catch {
            notice = AppNotice(title: "Deletion Not Ready", message: error.localizedDescription)
        }
    }

    func loadProjects(for userID: UUID? = nil) async {
        guard let resolvedUserID = userID ?? currentUser?.id else { return }

        do {
            projects = try await container.projectRepository.fetchProjects(for: resolvedUserID)
        } catch {
            notice = AppNotice(title: "Couldn't Load Projects", message: error.localizedDescription)
        }
    }

    func save(project: SpaceProject) async {
        do {
            let saved = try await container.projectRepository.save(project: project)
            if let index = projects.firstIndex(where: { $0.id == saved.id }) {
                projects[index] = saved
            } else {
                projects.insert(saved, at: 0)
            }
            projects.sort(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            notice = AppNotice(title: "Couldn't Save Project", message: error.localizedDescription)
        }
    }

    func delete(projectID: UUID) async {
        guard let userID = currentUser?.id else { return }

        do {
            try await container.projectRepository.delete(projectID: projectID, for: userID)
            projects.removeAll { $0.id == projectID }
        } catch {
            notice = AppNotice(title: "Couldn't Delete Project", message: error.localizedDescription)
        }
    }
}
