import SwiftUI

struct AuthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Welcome back to Reset My Space")
                        .font(BrandTypography.screenTitle)
                        .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                    Text("Sign in to save projects, compare progress, and build staged shopping lists over time.")
                        .font(BrandTypography.body)
                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 56)

                BrandCard {
                    VStack(spacing: 18) {
                        Picker("Auth Mode", selection: $viewModel.isSigningUp) {
                            Text("Sign In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(.segmented)

                        if viewModel.isSigningUp {
                            textField("Name", text: $viewModel.name)
                        }

                        textField("Email", text: $viewModel.email, keyboard: .emailAddress)
                        secureField("Password", text: $viewModel.password)

                        PrimaryActionButton(viewModel.isSigningUp ? "Create Account" : "Sign In") {
                            Task {
                                await handlePrimaryAction()
                            }
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .tint(BrandColor.teal)
                        }
                    }
                }

                BrandCard {
                    VStack(spacing: 14) {
                        socialButton(title: "Continue with Apple", symbol: "apple.logo") {
                            Task {
                                await handleApple()
                            }
                        }
                        socialButton(title: "Continue with Google", symbol: "globe") {
                            Task {
                                await handleGoogle()
                            }
                        }
                        Button("Continue as Guest") {
                            Task {
                                let user = await viewModel.continueAsGuest(using: appModel.container.authService)
                                await appModel.signIn(user: user)
                            }
                        }
                        .font(BrandTypography.bodyStrong)
                        .foregroundStyle(BrandColor.teal)
                    }
                }

                Button("Forgot Password") {
                    Task {
                        do {
                            try await viewModel.resetPassword(using: appModel.container.authService)
                            appModel.notice = AppNotice(title: "Email Ready", message: "Password reset is scaffolded. Wire the live provider to send production reset emails.")
                        } catch {
                            appModel.notice = AppNotice(title: "Couldn't Start Reset", message: error.localizedDescription)
                        }
                    }
                }
                .font(BrandTypography.caption)
                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }

    private func handlePrimaryAction() async {
        do {
            let user = try await viewModel.submit(using: appModel.container.authService)
            await appModel.signIn(user: user)
        } catch {
            appModel.notice = AppNotice(title: "Couldn't Continue", message: error.localizedDescription)
        }
    }

    private func handleApple() async {
        do {
            let user = try await viewModel.signInWithApple(using: appModel.container.authService)
            await appModel.signIn(user: user)
        } catch {
            appModel.notice = AppNotice(title: "Apple Sign-In Needs Finishing", message: error.localizedDescription)
        }
    }

    private func handleGoogle() async {
        do {
            let user = try await viewModel.signInWithGoogle(using: appModel.container.authService)
            await appModel.signIn(user: user)
        } catch {
            appModel.notice = AppNotice(title: "Google Sign-In Needs Finishing", message: error.localizedDescription)
        }
    }

    private func textField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
            .autocorrectionDisabled(keyboard == .emailAddress)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(BrandColor.elevatedBackground(for: colorScheme)))
            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textInputAutocapitalization(.never)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(BrandColor.elevatedBackground(for: colorScheme)))
            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
    }

    private func socialButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.headline)
                Text(title)
                    .font(BrandTypography.bodyStrong)
                Spacer()
            }
            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BrandColor.elevatedBackground(for: colorScheme))
            )
        }
        .buttonStyle(.plain)
    }
}
