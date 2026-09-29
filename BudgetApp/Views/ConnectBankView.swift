import SwiftUI
import LinkKit
import Supabase

// Use SwiftUI.Environment to avoid conflict with LinkKit's Environment
private typealias Env = SwiftUI.Environment

/// Retains the Plaid handler and ensures continuation is only resumed once
private final class PlaidLinkCoordinator {
    var continuation: CheckedContinuation<String, Error>?
    var handler: Handler?
    private var didResume = false

    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    func resumeSuccess(_ token: String) {
        guard !didResume else { return }
        didResume = true
        continuation?.resume(returning: token)
        continuation = nil
    }

    func resumeExit(_ error: Error) {
        guard !didResume else { return }
        didResume = true
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

/// Presents Plaid Link and handles the full flow: link_token → Link UI → exchange → refresh
struct ConnectBankView: View {
    @Env(\.theme) private var theme
    @Env(\.dismiss) private var dismiss
    @StateObject private var plaid = PlaidService.shared
    @StateObject private var data = SupabaseDataService.shared

    @State private var isLinking = false
    @State private var linkError: String?
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXL) {
                VStack(spacing: AppTheme.spacingM) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(theme.accentPrimary)
                    Text("Connect your bank")
                        .font(AppTheme.Typography.title2)
                        .foregroundStyle(theme.textPrimary)
                    Text("Securely link your accounts to see real transactions and balances in BudgetApp.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppTheme.spacingXXL)

                if let err = linkError {
                    Text(err)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.accentRed)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Button {
                    Task { await connectBank() }
                } label: {
                    HStack(spacing: AppTheme.spacingS) {
                        if isLinking {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "link")
                            Text("Connect Bank")
                        }
                    }
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingL)
                    .background(theme.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .disabled(isLinking)
                .buttonStyle(.plain)
                .padding(.horizontal, AppTheme.spacingXXL)

                if showSuccess, let last = plaid.lastLinkSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.accentGreen)
                        Text("Connected! \(last.accounts) accounts, \(last.transactions) transactions synced.")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(theme.accentGreen)
                    }
                    .padding()
                }
            }
            .padding(.bottom, AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Connect Bank")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
        .onAppear { linkError = nil; showSuccess = false }
    }

    private func connectBank() async {
        let token: String
        do {
            let session = try await SupabaseService.shared.client.auth.session
            token = session.accessToken
        } catch {
            linkError = "Please sign in first"
            return
        }

        isLinking = true
        linkError = nil

        do {
            let linkToken = try await plaid.fetchLinkToken(authToken: token)
            let publicToken = try await presentPlaidLink(linkToken: linkToken)
            let result = try await plaid.exchangeToken(publicToken: publicToken, authToken: token)
            plaid.lastLinkSuccess = (result.accounts, result.transactions)
            showSuccess = true
            await data.fetchAll()
        } catch {
            linkError = error.localizedDescription
        }

        isLinking = false
    }

    private func presentPlaidLink(linkToken: String) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let coordinator = PlaidLinkCoordinator(continuation: continuation)
            var config = LinkTokenConfiguration(
                token: linkToken,
                onSuccess: { success in
                    coordinator.resumeSuccess(success.publicToken)
                }
            )
            config.onExit = { exit in
                if let err = exit.error {
                    let msg = (err as NSError).localizedDescription
                    coordinator.resumeExit(PlaidError.server(msg.isEmpty ? "Link error" : msg))
                } else {
                    coordinator.resumeExit(PlaidError.server("Link was closed"))
                }
            }

            let result = Plaid.create(config)
            switch result {
            case .failure(let err):
                coordinator.resumeExit(err)
            case .success(let handler):
                coordinator.handler = handler
                guard let vc = topViewController() else {
                    coordinator.resumeExit(PlaidError.server("Could not present Link"))
                    return
                }
                handler.open(presentUsing: .viewController(vc))
            }
        }
    }

    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var vc = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = vc?.presentedViewController {
            vc = presented
        }
        return vc
    }
}
