import Foundation

@MainActor
protocol AuthService {
    var supportsAppleSignIn: Bool { get }
    var supportsGoogleSignIn: Bool { get }

    func restoreSession() async -> UserProfile?
    func signIn(email: String, password: String) async throws -> UserProfile
    func signUp(name: String, email: String, password: String) async throws -> UserProfile
    func continueWithApple() async throws -> UserProfile
    func continueWithGoogle() async throws -> UserProfile
    func continueAsGuest() async -> UserProfile
    func resetPassword(email: String) async throws
    func signOut() async throws
    func deleteAccount() async throws
}
