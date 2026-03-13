import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isSigningUp = false
    @Published var isLoading = false

    func submit(using authService: AuthService) async throws -> UserProfile {
        isLoading = true
        defer { isLoading = false }

        if isSigningUp {
            return try await authService.signUp(name: name, email: email, password: password)
        }

        return try await authService.signIn(email: email, password: password)
    }

    func signInWithApple(using authService: AuthService) async throws -> UserProfile {
        isLoading = true
        defer { isLoading = false }
        return try await authService.continueWithApple()
    }

    func signInWithGoogle(using authService: AuthService) async throws -> UserProfile {
        isLoading = true
        defer { isLoading = false }
        return try await authService.continueWithGoogle()
    }

    func continueAsGuest(using authService: AuthService) async -> UserProfile {
        isLoading = true
        defer { isLoading = false }
        return await authService.continueAsGuest()
    }

    func resetPassword(using authService: AuthService) async throws {
        isLoading = true
        defer { isLoading = false }
        try await authService.resetPassword(email: email)
    }
}
