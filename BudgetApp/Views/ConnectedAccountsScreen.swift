import SwiftUI
import Supabase

// MARK: - Connected Accounts Screen (Financial Dashboard Style)

struct ConnectedAccountsScreen: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var data = SupabaseDataService.shared
    @StateObject private var plaid = PlaidService.shared
    @State private var expandedSections: Set<AccountSection> = [.checking, .savings, .investments, .creditCards, .loans]
    @State private var showDisconnectAlert = false
    @State private var showDisconnectError = false
    @State private var disconnectError: String?
    @State private var isRefreshing = false

    private var visibleAccounts: [Account] {
        data.accounts.filter { !$0.isHidden }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXL) {
                if visibleAccounts.isEmpty {
                    emptyState
                } else {
                    assetsSection
                    liabilitiesSection
                    connectBankButton
                    disconnectButton
                }
            }
            .padding(AppTheme.spacingXXL)
            .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Connected Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !visibleAccounts.isEmpty {
                    Button {
                        Task { await performRefresh() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
        }
        .alert("Disconnect Failed", isPresented: $showDisconnectError) {
            Button("OK") { showDisconnectError = false }
        } message: {
            Text(disconnectError ?? "Something went wrong")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingM) {
            Text("No accounts linked yet")
                .font(AppTheme.Typography.body)
                .foregroundStyle(theme.textSecondary)
            NavigationLink {
                ConnectBankView()
            } label: {
                Text("Connect Bank")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.spacingXL)
                    .padding(.vertical, AppTheme.spacingM)
                    .background(theme.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXXL)
    }

    // MARK: - Assets Section

    private var assetsSection: some View {
        let checkingAccounts = visibleAccounts.filter { $0.categoryGroup == .checking }
        let savingsAccounts = visibleAccounts.filter { $0.categoryGroup == .savings }
        let investmentAccounts = visibleAccounts.filter { $0.categoryGroup == .investments }
        let assetAccounts = checkingAccounts + savingsAccounts + investmentAccounts
        let totalAssets = assetAccounts.reduce(0) { $0 + $1.netWorthBalance }

        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            sectionHeader(title: "Assets", total: totalAssets, color: theme.accentGreen)

            if !checkingAccounts.isEmpty {
                accountSubsection(
                    title: "Checking",
                    accounts: checkingAccounts,
                    isExpanded: expandedSections.contains(.checking),
                    color: theme.accentGreen
                ) {
                    toggleSection(.checking)
                }
            }

            if !savingsAccounts.isEmpty {
                accountSubsection(
                    title: "Savings",
                    accounts: savingsAccounts,
                    isExpanded: expandedSections.contains(.savings),
                    color: theme.accentGreen
                ) {
                    toggleSection(.savings)
                }
            }

            if !investmentAccounts.isEmpty {
                accountSubsection(
                    title: "Investments",
                    accounts: investmentAccounts,
                    isExpanded: expandedSections.contains(.investments),
                    color: theme.accentGreen
                ) {
                    toggleSection(.investments)
                }
            }

            if assetAccounts.isEmpty {
                assetsEmptyState
            }
        }
    }

    private var assetsEmptyState: some View {
        NavigationLink {
            ConnectBankView()
        } label: {
            HStack(spacing: AppTheme.spacingM) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(theme.accentGreen.opacity(0.8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect bank accounts")
                        .font(AppTheme.Typography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.textPrimary)
                    Text("Checking, savings, and investments")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(AppTheme.spacingL)
            .background(theme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Liabilities Section

    private var liabilitiesSection: some View {
        let creditAccounts = visibleAccounts.filter { $0.categoryGroup == .creditCards }
        let loanAccounts = visibleAccounts.filter { $0.categoryGroup == .loans }
        let liabilityAccounts = creditAccounts + loanAccounts
        let totalLiabilities = abs(liabilityAccounts.reduce(0) { $0 + $1.netWorthBalance })

        guard totalLiabilities != 0 || !creditAccounts.isEmpty || !loanAccounts.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                sectionHeader(title: "Liabilities", total: -totalLiabilities, color: theme.accentRed)

                if !creditAccounts.isEmpty {
                    accountSubsection(
                        title: "Credit Cards",
                        accounts: creditAccounts,
                        isExpanded: expandedSections.contains(.creditCards),
                        color: theme.accentRed
                    ) {
                        toggleSection(.creditCards)
                    }
                }

                if !loanAccounts.isEmpty {
                    accountSubsection(
                        title: "Loans",
                        accounts: loanAccounts,
                        isExpanded: expandedSections.contains(.loans),
                        color: theme.accentRed
                    ) {
                        toggleSection(.loans)
                    }
                }
            }
        )
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, total: Double, color: Color) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Text(formatCurrency(total))
                .font(AppTheme.Typography.headline)
                .foregroundStyle(color)
        }
        .padding(AppTheme.spacingM)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    // MARK: - Account Subsection (Collapsible)

    private func accountSubsection(
        title: String,
        accounts: [Account],
        isExpanded: Bool,
        color: Color,
        onTap: @escaping () -> Void
    ) -> some View {
        let total = accounts.reduce(0) { $0 + $1.displayBalance }
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { onTap() }
            } label: {
                HStack {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Text(formatCurrency(total))
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(color)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(AppTheme.spacingM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: AppTheme.spacingXS) {
                    ForEach(accountsGroupedByInstitution(accounts), id: \.0) { institution, instAccounts in
                        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                            Text(institution)
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(theme.textSecondary)
                            ForEach(instAccounts) { account in
                                AccountRowView(account: account, color: color)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.spacingM)
                .padding(.bottom, AppTheme.spacingM)
            }
        }
        .background(theme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private func toggleSection(_ section: AccountSection) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }

    private func accountsGroupedByInstitution(_ accounts: [Account]) -> [(String, [Account])] {
        let grouped = Dictionary(grouping: accounts) { $0.institution ?? "Unknown" }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    // MARK: - Connect Bank Button

    private var connectBankButton: some View {
        NavigationLink {
            ConnectBankView()
        } label: {
            HStack {
                Image(systemName: "link")
                Text("Connect Another Bank")
            }
            .font(AppTheme.Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(theme.accentPrimary)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacingM)
            .background(theme.accentPrimary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Disconnect Button

    private var disconnectButton: some View {
        Button {
            showDisconnectAlert = true
        } label: {
            HStack {
                Image(systemName: "link.badge.minus")
                Text("Disconnect All Institutions")
            }
            .font(AppTheme.Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(theme.accentRed)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacingM)
            .background(theme.accentRed.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(plaid.isLoading)
        .alert("Disconnect All Institutions?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                Task { await performDisconnect() }
            }
        } message: {
            Text("This will remove all linked bank accounts, credit cards, and loans. Your transaction history will be deleted. You can reconnect anytime.")
        }
    }

    private func performRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let session = try await SupabaseService.shared.client.auth.session
            _ = try await plaid.refreshAccounts(authToken: session.accessToken)
            await data.fetchAll()
        } catch {
            disconnectError = error.localizedDescription
            showDisconnectError = true
        }
    }

    private func performDisconnect() async {
        do {
            let client = SupabaseService.shared.client
            try await client.auth.refreshSession()
            let session = try await client.auth.session
            try await plaid.disconnectAllInstitutions(authToken: session.accessToken)
            await data.fetchAll()
            dismiss()
        } catch {
            disconnectError = error.localizedDescription
            showDisconnectError = true
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Account Section (for expand state)

private enum AccountSection: Hashable {
    case checking, savings, investments, creditCards, loans
}

// MARK: - Account Row

struct AccountRowView: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared
    let account: Account
    let color: Color
    @State private var showRenameAlert = false
    @State private var renameText = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textPrimary)
                HStack(spacing: 4) {
                    if let inst = account.institution, !inst.isEmpty {
                        Text(inst)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    Text("•")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.textTertiary)
                    Text(account.accountSubtypeLabel)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
            Text(formatCurrency(account.displayBalance))
                .font(AppTheme.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(AppTheme.spacingM)
        .background(theme.backgroundPrimary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS))
        .contextMenu {
            Button {
                Task { await data.toggleAccountIncludeInNetWorth(account) }
            } label: {
                Label(
                    account.includeInNetWorth ? "Exclude from net worth" : "Include in net worth",
                    systemImage: account.includeInNetWorth ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis"
                )
            }
            Button {
                renameText = account.displayName
                showRenameAlert = true
            } label: {
                Label("Rename account", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task { await data.hideAccount(account) }
            } label: {
                Label("Hide account", systemImage: "eye.slash")
            }
        }
        .alert("Rename account", isPresented: $showRenameAlert) {
            TextField("Account name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                Task { await data.renameAccount(account, to: renameText) }
            }
        } message: {
            Text("Enter a custom name for this account.")
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}
