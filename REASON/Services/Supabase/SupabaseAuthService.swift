import AuthenticationServices
import Foundation
import Supabase

final class SupabaseAuthService: AuthService {
    private let clientFactory: SupabaseClientFactory

    let supportsAppleSignIn = true
    let supportsGoogleSignIn = false

    init(clientFactory: SupabaseClientFactory) {
        self.clientFactory = clientFactory
    }

    // MARK: - Session

    func restoreSession() async -> UserProfile? {
        guard let client = try? clientFactory.makeClient() else { return nil }
        do {
            let session = try await client.auth.session
            do {
                return try await fetchOrCreateProfile(
                    client: client,
                    userID: session.user.id,
                    email: session.user.email ?? "",
                    authMethod: .email
                )
            } catch {
                print("⚠️ [SupabaseAuthService] Failed to restore profile: \(error)")
                return bestEffortProfile(
                    userID: session.user.id,
                    email: session.user.email ?? "",
                    displayName: nil,
                    createdAt: session.user.createdAt,
                    updatedAt: session.user.updatedAt,
                    authMethod: .email
                )
            }
        } catch {
            print("⚠️ [SupabaseAuthService] Failed to restore session: \(error)")
            return nil
        }
    }

    // MARK: - Email auth

    func signIn(email: String, password: String) async throws -> UserProfile {
        let client = try clientFactory.makeClient()
        let session = try await client.auth.signIn(email: email, password: password)
        do {
            return try await fetchOrCreateProfile(
                client: client,
                userID: session.user.id,
                email: session.user.email ?? email,
                authMethod: .email
            )
        } catch {
            print("⚠️ [SupabaseAuthService] Failed to fetch profile after sign-in: \(error)")
            return bestEffortProfile(
                userID: session.user.id,
                email: session.user.email ?? email,
                displayName: nil,
                createdAt: session.user.createdAt,
                updatedAt: session.user.updatedAt,
                authMethod: .email
            )
        }
    }

    func signUp(name: String, email: String, password: String) async throws -> UserProfile {
        let client = try clientFactory.makeClient()
        let response = try await client.auth.signUp(email: email, password: password)

        guard let session = response.session else {
            throw AppError.unavailable("Account created. Check your email to confirm it, then sign in.")
        }

        do {
            return try await fetchOrCreateProfile(
                client: client,
                userID: session.user.id,
                email: session.user.email ?? email,
                displayName: name,
                authMethod: .email
            )
        } catch {
            print("⚠️ [SupabaseAuthService] Failed to create profile after sign-up: \(error)")
            return bestEffortProfile(
                userID: session.user.id,
                email: session.user.email ?? email,
                displayName: name,
                createdAt: session.user.createdAt,
                updatedAt: session.user.updatedAt,
                authMethod: .email
            )
        }
    }

    // MARK: - Apple Sign In

    func continueWithApple() async throws -> UserProfile {
        let coordinator = AppleSignInCoordinator()
        let result = try await coordinator.signIn()

        let client = try clientFactory.makeClient()
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: result.idToken, nonce: result.nonce)
        )

        let email = result.email ?? session.user.email ?? ""
        do {
            return try await fetchOrCreateProfile(
                client: client,
                userID: session.user.id,
                email: email,
                displayName: result.fullName,
                authMethod: .apple
            )
        } catch {
            print("⚠️ [SupabaseAuthService] Failed to fetch Apple profile: \(error)")
            return bestEffortProfile(
                userID: session.user.id,
                email: email,
                displayName: result.fullName,
                createdAt: session.user.createdAt,
                updatedAt: session.user.updatedAt,
                authMethod: .apple
            )
        }
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

    private func fetchOrCreateProfile(
        client: SupabaseClient,
        userID: UUID,
        email: String,
        displayName: String? = nil,
        authMethod: AuthMethod
    ) async throws -> UserProfile {
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
                authMethod: authMethod
            )
        }

        let name = displayName ?? email.components(separatedBy: "@").first?.capitalized ?? "User"
        return try await upsertProfile(
            client: client,
            userID: userID,
            email: email,
            displayName: name,
            authMethod: authMethod
        )
    }

    private func upsertProfile(
        client: SupabaseClient,
        userID: UUID,
        email: String,
        displayName: String,
        authMethod: AuthMethod
    ) async throws -> UserProfile {
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
            authMethod: authMethod
        )
    }

    private func bestEffortProfile(
        userID: UUID,
        email: String,
        displayName: String?,
        createdAt: Date,
        updatedAt: Date,
        authMethod: AuthMethod
    ) -> UserProfile {
        let resolvedName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = email.components(separatedBy: "@").first?.capitalized ?? "User"

        return UserProfile(
            id: userID,
            email: email,
            displayName: resolvedName?.isEmpty == false ? resolvedName! : fallbackName,
            avatarURL: nil,
            createdAt: createdAt,
            updatedAt: updatedAt,
            preferredTheme: .system,
            preferredTone: "warm",
            onboardingCompleted: false,
            authMethod: authMethod
        )
    }
}
