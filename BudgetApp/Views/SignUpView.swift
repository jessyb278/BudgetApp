import SwiftUI

struct SignUpView: View {
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
                        Text("Create account")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundStyle(theme.textPrimary)
                        Text("Sign up to get started")
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
                            .textContentType(.newPassword)
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
                            Task { await signUp() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign Up")
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
                        showSignUp = false
                    } label: {
                        Text("Already have an account? Sign in")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(theme.accentPrimary)
                    }
                    .padding(.top, AppTheme.spacingM)

                    Spacer(minLength: 80)
                }
            }
        }
    }

    private func signUp() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.signUp(email: email, password: password)
        } catch {
            auth.authError = error.localizedDescription
        }
    }
}
