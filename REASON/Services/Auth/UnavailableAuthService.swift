import Foundation

final class UnavailableAuthService: AuthService {
    let supportsAppleSignIn = false
    let supportsGoogleSignIn = false
    let supportsGuestAccess = false

    private let message: String

    init(message: String) {
        self.message = message
    }

    func restoreSession() async -> UserProfile? {
        nil
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        throw AppError.configuration(message)
    }

    func signUp(name: String, email: String, password: String) async throws -> UserProfile {
        throw AppError.configuration(message)
    }

    func continueWithApple() async throws -> UserProfile {
        throw AppError.configuration(message)
    }

    func continueWithGoogle() async throws -> UserProfile {
        throw AppError.configuration(message)
    }

    func continueAsGuest() async throws -> UserProfile {
        throw AppError.unavailable("Guest mode is disabled in the live build. Sign in with a real account to keep testing.")
    }

    func resetPassword(email: String) async throws {
        throw AppError.configuration(message)
    }

    func signOut() async throws { }

    func deleteAccount() async throws {
        throw AppError.configuration(message)
    }
}
