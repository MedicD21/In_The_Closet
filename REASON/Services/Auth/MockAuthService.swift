import Foundation

final class MockAuthService: AuthService {
    private let storageKey = "reason.mock.user"

    let supportsAppleSignIn = true
    let supportsGoogleSignIn = true

    func restoreSession() async -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }

        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        guard !email.isEmpty, !password.isEmpty else {
            throw AppError.validation("Enter both email and password to continue.")
        }

        let user = makeUser(
            name: email.components(separatedBy: "@").first?.capitalized ?? "Reset My Space User",
            email: email,
            authMethod: .email
        )
        persist(user)
        return user
    }

    func signUp(name: String, email: String, password: String) async throws -> UserProfile {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AppError.validation("Fill out each field so we can create your account.")
        }

        let user = makeUser(name: name, email: email, authMethod: .email)
        persist(user)
        return user
    }

    func continueWithApple() async throws -> UserProfile {
        let user = makeUser(name: "Apple User", email: "apple@reason.app", authMethod: .apple)
        persist(user)
        return user
    }

    func continueWithGoogle() async throws -> UserProfile {
        let user = makeUser(name: "Google User", email: "google@reason.app", authMethod: .google)
        persist(user)
        return user
    }

    func continueAsGuest() async -> UserProfile {
        let user = makeUser(name: "Guest", email: "guest@reason.app", authMethod: .guest)
        persist(user)
        return user
    }

    func resetPassword(email: String) async throws {
        guard !email.isEmpty else {
            throw AppError.validation("Enter an email address first.")
        }
    }

    func signOut() async throws {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func deleteAccount() async throws {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func makeUser(name: String, email: String, authMethod: AuthMethod) -> UserProfile {
        UserProfile(
            id: UUID(),
            email: email,
            displayName: name,
            avatarURL: nil,
            createdAt: .now,
            updatedAt: .now,
            preferredTheme: .system,
            preferredTone: "warm",
            onboardingCompleted: true,
            authMethod: authMethod
        )
    }

    private func persist(_ user: UserProfile) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
