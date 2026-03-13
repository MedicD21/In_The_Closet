import Foundation
import Supabase

final class SupabaseAuthService: AuthService {
    private let clientFactory: SupabaseClientFactory

    init(clientFactory: SupabaseClientFactory) {
        self.clientFactory = clientFactory
    }

    func restoreSession() async -> UserProfile? {
        nil
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Supabase email auth mapping still needs to be completed. The scaffold is in place, but the live exchange and profile sync are still TODOs.")
    }

    func signUp(name: String, email: String, password: String) async throws -> UserProfile {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Supabase sign-up wiring still needs the final profile creation call.")
    }

    func continueWithApple() async throws -> UserProfile {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Sign in with Apple requires the final token exchange and nonce flow.")
    }

    func continueWithGoogle() async throws -> UserProfile {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Google sign-in needs the Google SDK token handoff before the Supabase exchange can be finished.")
    }

    func continueAsGuest() async -> UserProfile {
        UserProfile(
            id: UUID(),
            email: "guest@reason.app",
            displayName: "Guest",
            avatarURL: nil,
            createdAt: .now,
            updatedAt: .now,
            preferredTheme: .system,
            preferredTone: "warm",
            onboardingCompleted: true,
            authMethod: .guest
        )
    }

    func resetPassword(email: String) async throws {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Reset password is scaffolded but still needs the live Supabase auth call.")
    }

    func signOut() async throws { }

    func deleteAccount() async throws {
        throw AppError.unavailable("Account deletion should be finalized with a server-side cleanup routine before shipping.")
    }
}
