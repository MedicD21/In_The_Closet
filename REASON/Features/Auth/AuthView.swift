import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var viewModel = AuthViewModel()

    @State private var appeared = false

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()
            RadialGradient(
                colors: [BrandColor.tealMuted, .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 60)

                    // App icon + title
                    VStack(spacing: 12) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Text("Reset My Space")
                            .font(BrandTypography.displayTitle)
                            .foregroundColor(BrandColor.textPrimary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                    // Sign In / Sign Up segmented control
                    segmentedControl
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(response: 0.5).delay(0.06), value: appeared)

                    // Fields + primary action
                    fieldsSection
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.12), value: appeared)

                    // Social + guest
                    socialSection
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.18), value: appeared)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5)) { appeared = true }
        }
    }

    // MARK: — Segmented control

    private var segmentedControl: some View {
        GeometryReader { geo in
            ZStack(alignment: viewModel.isSigningUp ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(BrandColor.surfaceElevated)

                RoundedRectangle(cornerRadius: 12)
                    .fill(BrandColor.teal)
                    .frame(width: geo.size.width / 2, height: 36)
                    .padding(.horizontal, 4)
                    .animation(.spring(response: 0.4), value: viewModel.isSigningUp)

                HStack(spacing: 0) {
                    Button("Sign In") {
                        withAnimation { viewModel.isSigningUp = false }
                    }
                    .font(BrandTypography.button)
                    .foregroundColor(!viewModel.isSigningUp ? BrandColor.textPrimary : BrandColor.textSecondary)
                    .frame(maxWidth: .infinity)

                    Button("Sign Up") {
                        withAnimation { viewModel.isSigningUp = true }
                    }
                    .font(BrandTypography.button)
                    .foregroundColor(viewModel.isSigningUp ? BrandColor.textPrimary : BrandColor.textSecondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 44)
    }

    // MARK: — Fields

    private var fieldsSection: some View {
        VStack(spacing: 12) {
            if viewModel.isSigningUp {
                styledTextField("Name", text: $viewModel.name)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            styledTextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            styledSecureField("Password", text: $viewModel.password)

            PrimaryButton(
                viewModel.isSigningUp ? "Create Account" : "Sign In",
                isDisabled: viewModel.isLoading
            ) {
                Task {
                    do {
                        let user = try await viewModel.submit(using: appModel.container.authService)
                        await appModel.signIn(user: user)
                    } catch {
                        appModel.notice = AppNotice(title: "Error", message: error.localizedDescription)
                    }
                }
            }

            if !viewModel.isSigningUp {
                GhostButton(title: "Forgot Password?") {
                    Task {
                        do {
                            try await viewModel.resetPassword(using: appModel.container.authService)
                            appModel.notice = AppNotice(title: "Email Sent", message: "Check your inbox for a reset link.")
                        } catch {
                            appModel.notice = AppNotice(title: "Error", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
    }

    // MARK: — Social

    private var socialSection: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle().fill(BrandColor.divider).frame(height: 1)
                Text("or")
                    .font(BrandTypography.micro)
                    .foregroundColor(BrandColor.textTertiary)
                Rectangle().fill(BrandColor.divider).frame(height: 1)
            }

            if appModel.container.authService.supportsAppleSignIn {
                Button {
                    Task {
                        do {
                            let user = try await viewModel.signInWithApple(using: appModel.container.authService)
                            await appModel.signIn(user: user)
                        } catch {
                            appModel.notice = AppNotice(title: "Error", message: error.localizedDescription)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Continue with Apple")
                            .font(BrandTypography.button)
                    }
                    .foregroundColor(BrandColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(BrandColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(BrandColor.stroke, lineWidth: 0.5)
                    )
                }
            }

            if appModel.container.authService.supportsGoogleSignIn {
                Button {
                    Task {
                        do {
                            let user = try await viewModel.signInWithGoogle(using: appModel.container.authService)
                            await appModel.signIn(user: user)
                        } catch {
                            appModel.notice = AppNotice(title: "Error", message: error.localizedDescription)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("G")
                            .font(BrandTypography.bodyStrong)
                            .foregroundColor(BrandColor.coral)
                        Text("Continue with Google")
                            .font(BrandTypography.button)
                    }
                    .foregroundColor(BrandColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(BrandColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(BrandColor.stroke, lineWidth: 0.5)
                    )
                }
            }

            if appModel.container.authService.supportsGuestAccess {
                GhostButton(title: "Continue as Guest") {
                    Task {
                        do {
                            let user = try await viewModel.continueAsGuest(using: appModel.container.authService)
                            await appModel.signIn(user: user)
                        } catch {
                            appModel.notice = AppNotice(title: "Error", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
    }

    // MARK: — Helpers

    private func styledTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(BrandTypography.body)
            .foregroundColor(BrandColor.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(BrandColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BrandColor.stroke, lineWidth: 0.5)
            )
    }

    private func styledSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(BrandTypography.body)
            .foregroundColor(BrandColor.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(BrandColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BrandColor.stroke, lineWidth: 0.5)
            )
    }
}
