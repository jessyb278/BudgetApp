import SwiftUI

struct LoginView: View {
    @Environment(\.theme) private var theme
    @StateObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @Binding var showSignUp: Bool

    var body: some View {
        ZStack {
            theme.backgroundPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppTheme.spacingXXL) {
                    Spacer(minLength: 60)
                    VStack(spacing: AppTheme.spacingS) {
                        Text("Welcome back")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundStyle(theme.textPrimary)
                        Text("Sign in to continue")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: AppTheme.spacingL) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .padding(AppTheme.spacingL)
                            .background(theme.surfacePrimary)
                            .foregroundStyle(theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding(AppTheme.spacingL)
                            .background(theme.surfacePrimary)
                            .foregroundStyle(theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                        if let err = auth.authError {
                            Text(err)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(theme.accentRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await signIn() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.spacingL)
                            .background(theme.accentPrimary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.spacingXXL)

                    Button {
                        showSignUp = true
                    } label: {
                        Text("Don't have an account? Sign up")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(theme.accentPrimary)
                    }
                    .padding(.top, AppTheme.spacingM)

                    Spacer(minLength: 80)
                }
            }
        }
    }

    private func signIn() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            auth.authError = error.localizedDescription
        }
    }
}
