import Foundation
import Supabase

final class SupabaseAuthService: AuthService {
    private let clientFactory: SupabaseClientFactory

    init(clientFactory: SupabaseClientFactory) {
        self.clientFactory = clientFactory
    }

    // MARK: - Session

    func restoreSession() async -> UserProfile? {
        guard let client = try? clientFactory.makeClient() else { return nil }
        do {
            let session = try await client.auth.session
            return try await fetchOrCreateProfile(client: client, userID: session.user.id, email: session.user.email ?? "")
        } catch {
            return nil
        }
    }

    // MARK: - Email auth

    func signIn(email: String, password: String) async throws -> UserProfile {
        let client = try clientFactory.makeClient()
        let session = try await client.auth.signIn(email: email, password: password)
        return try await fetchOrCreateProfile(client: client, userID: session.user.id, email: session.user.email ?? email)
    }

    func signUp(name: String, email: String, password: String) async throws -> UserProfile {
        let client = try clientFactory.makeClient()
        let session = try await client.auth.signUp(email: email, password: password)
        return try await upsertProfile(
            client: client,
            userID: session.user.id,
            email: session.user.email ?? email,
            displayName: name
        )
    }

    // MARK: - Social auth (scaffolded — requires final OAuth token handoff)

    func continueWithApple() async throws -> UserProfile {
        throw AppError.unavailable("Sign in with Apple requires the final token exchange and nonce flow.")
    }

    func continueWithGoogle() async throws -> UserProfile {
        throw AppError.unavailable("Google sign-in needs the Google SDK token handoff before the Supabase exchange can be finished.")
    }

    // MARK: - Guest

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

    // MARK: - Other

    func resetPassword(email: String) async throws {
        let client = try clientFactory.makeClient()
        try await client.auth.resetPasswordForEmail(email)
    }

    func signOut() async throws {
        let client = try clientFactory.makeClient()
        try await client.auth.signOut()
    }

    func deleteAccount() async throws {
        throw AppError.unavailable("Account deletion should be finalized with a server-side cleanup routine before shipping.")
    }

    // MARK: - Profile helpers

    private func fetchOrCreateProfile(client: SupabaseClient, userID: UUID, email: String) async throws -> UserProfile {
        struct ProfileRow: Decodable {
            let id: UUID
            let email: String?
            let display_name: String?
            let avatar_url: String?
            let preferred_theme: String?
            let preferred_tone: String?
            let onboarding_completed: Bool?
            let created_at: Date
            let updated_at: Date
        }

        let rows: [ProfileRow] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value

        if let row = rows.first {
            return UserProfile(
                id: row.id,
                email: row.email ?? email,
                displayName: row.display_name ?? email.components(separatedBy: "@").first?.capitalized ?? "User",
                avatarURL: row.avatar_url.flatMap { URL(string: $0) },
                createdAt: row.created_at,
                updatedAt: row.updated_at,
                preferredTheme: AppThemePreference(rawValue: row.preferred_theme ?? "system") ?? .system,
                preferredTone: row.preferred_tone ?? "warm",
                onboardingCompleted: row.onboarding_completed ?? false,
                authMethod: .email
            )
        }

        return try await upsertProfile(
            client: client,
            userID: userID,
            email: email,
            displayName: email.components(separatedBy: "@").first?.capitalized ?? "User"
        )
    }

    private func upsertProfile(client: SupabaseClient, userID: UUID, email: String, displayName: String) async throws -> UserProfile {
        let now = Date.now

        struct ProfileInsert: Encodable {
            let id: String
            let email: String
            let display_name: String
            let preferred_theme: String
            let preferred_tone: String
            let onboarding_completed: Bool
        }

        try await client
            .from("profiles")
            .upsert(ProfileInsert(
                id: userID.uuidString,
                email: email,
                display_name: displayName,
                preferred_theme: "system",
                preferred_tone: "warm",
                onboarding_completed: false
            ))
            .execute()

        return UserProfile(
            id: userID,
            email: email,
            displayName: displayName,
            avatarURL: nil,
            createdAt: now,
            updatedAt: now,
            preferredTheme: .system,
            preferredTone: "warm",
            onboardingCompleted: false,
            authMethod: .email
        )
    }
}
