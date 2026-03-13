import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

/// Bridges ASAuthorizationController's delegate callbacks into an async/await continuation.
final class AppleSignInCoordinator: NSObject {
    struct Result {
        let idToken: String
        let nonce: String
        let fullName: String?
        let email: String?
    }

    private var continuation: CheckedContinuation<Result, Error>?
    private var currentNonce: String?

    @MainActor
    func signIn() async throws -> Result {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let nonce = randomNonce()
            self.currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let idTokenData = credential.identityToken,
            let idToken = String(data: idTokenData, encoding: .utf8),
            let nonce = currentNonce
        else {
            continuation?.resume(throwing: AppError.unavailable("Apple Sign In returned an invalid credential."))
            continuation = nil
            return
        }

        var fullName: String?
        if let components = credential.fullName {
            let formatted = PersonNameComponentsFormatter().string(from: components).trimmingCharacters(in: .whitespaces)
            fullName = formatted.isEmpty ? nil : formatted
        }

        continuation?.resume(returning: Result(
            idToken: idToken,
            nonce: nonce,
            fullName: fullName,
            email: credential.email
        ))
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
