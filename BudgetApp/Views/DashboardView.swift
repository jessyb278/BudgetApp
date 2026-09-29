import SwiftUI
import Supabase

enum HomeRoute: Hashable {
    case netWorth
    case spending
    case creditScore
    case insights
    case connectedAccounts
    case transaction(UUID)
    case budgets
    case budget(UUID)
    case goals
    case goal(UUID)
}

struct DashboardView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var appState: AppState
    @StateObject private var data = SupabaseDataService.shared
    @State private var selectedMetricIndex = 0
    @State private var cardAppeared: [Bool] = [false, false, false]
    @State private var path = NavigationPath()
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                backgroundLayer
                
                if let err = data.errorMessage {
                    VStack {
                        Text(err)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(theme.accentRed)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                
                ScrollView {
                    VStack(spacing: AppTheme.spacingXL) {
                        metricCardsSection
                            .offset(y: -6)
                        
                        if let insight = data.primaryInsight {
                            InsightStripCard(
                                message: insight.message,
                                type: insight.type,
                                onTap: { path.append(HomeRoute.insights) }
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        connectedAccountsSection
                        
                        budgetSnapshot
                        
                        goalsProgress
                    }
                    .padding(.horizontal, AppTheme.spacingXXL)
                    .padding(.top, AppTheme.spacingM)
                    .padding(.bottom, AppTheme.spacingXXL + AppTheme.tabBarHeight + AppTheme.spacingXL)
                }
                .ignoresSafeArea(edges: .bottom)
                .refreshable {
                    await refresh()
                }
                .overlay {
                    if data.isLoading && data.transactions.isEmpty && data.accounts.isEmpty {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        ProgressView("Loading...")
                            .tint(theme.textPrimary)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .netWorth:
                    NetWorthDetailScreen()
                case .spending:
                    SpendingDetailScreen()
                case .creditScore:
                    CreditScoreDetailScreen()
                case .insights:
                    InsightsHubScreen()
                case .connectedAccounts:
                    ConnectedAccountsScreen()
                case .transaction(let id):
                    if let tx = data.transactions.first(where: { $0.id == id }) {
                        TransactionDetailScreen(transaction: tx)
                    }
                case .budgets:
                    BudgetsListScreen(
                        budgets: fullBudgets,
                        transactions: data.transactions
                    )
                case .budget(let id):
                    if let budget = fullBudgets.first(where: { $0.id == id }) {
                        BudgetDetailScreen(
                            budget: budget,
                            transactions: data.transactions.filter { $0.category == budget.category }
                        )
                    }
                case .goals:
                    GoalsListScreen(goals: fullGoals)
                case .goal(let id):
                    if let goal = fullGoals.first(where: { $0.id == id }) {
                        GoalDetailScreen(goal: goal)
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            theme.backgroundPrimary.ignoresSafeArea()
            if theme.isDarkMode {
                RadialGradient(
                    colors: [
                        theme.accentPrimary.opacity(theme.accentGradientOpacity),
                        theme.accentPrimary.opacity(theme.radialGradientOpacity),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.12),
                    startRadius: 0,
                    endRadius: 350
                )
                .ignoresSafeArea()
            }
        }
    }
    
    private var metricCardsSection: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedMetricIndex) {
                netWorthCard.tag(0)
                spendingCard.tag(1)
                creditScoreCard.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: AppTheme.DASHBOARD_CARD_HEIGHT)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == selectedMetricIndex ? theme.accentPrimary : theme.textTertiary.opacity(0.4))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 8)
        }
        .frame(height: AppTheme.DASHBOARD_CARD_HEIGHT + 32)
    }
    
    private var netWorthCard: some View {
        DashboardMetricCardContainer {
        NetWorthCard(
            netWorth: data.netWorth,
            changeAmount: netWorthDeltaValue,
            history: data.netWorthHistory,
            insight: data.netWorthInsight,
            historyForRange: { data.netWorthHistory(months: $0) },
            onTap: { path.append(HomeRoute.netWorth) }
        )
        }
        .opacity(cardAppeared[0] ? 1 : 0)
        .offset(y: cardAppeared[0] ? 0 : 16)
        .onAppear {
            withAnimation(spring.delay(0.1)) { cardAppeared[0] = true }
        }
    }
    
    private var spendingCard: some View {
        DashboardMetricCardContainer {
        SmartSpendingCard(
            monthlySpending: data.monthlySpending,
            changeAmount: monthlySpendingDeltaValue,
            history: data.monthlySpendingHistory,
            direction: data.spendingDirection,
            threeMonthAverage: data.spendingThreeMonthAverage,
            paceOnTrack: data.spendingPaceOnTrack,
            topCategory: data.topSpendingCategory,
            onTap: { path.append(HomeRoute.spending) }
        )
        }
        .opacity(cardAppeared[1] ? 1 : 0)
        .offset(y: cardAppeared[1] ? 0 : 16)
        .onAppear {
            withAnimation(spring.delay(0.15)) { cardAppeared[1] = true }
        }
    }
    
    private var creditScoreCard: some View {
        DashboardMetricCardContainer {
        SmartCreditScoreCard(
            score: data.creditScore,
            change: data.creditScoreChange,
            keyFactor: data.creditScoreKeyFactor,
            suggestion: data.creditScoreSuggestion,
            isVisible: selectedMetricIndex == 2,
            onTap: { path.append(HomeRoute.creditScore) }
        )
        }
        .opacity(cardAppeared[2] ? 1 : 0)
        .offset(y: cardAppeared[2] ? 0 : 16)
        .onAppear {
            withAnimation(spring.delay(0.2)) { cardAppeared[2] = true }
        }
    }
    
    @State private var dashboardExpandedCategories: Set<Account.CategoryGroup> = []

    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            SectionHeader(title: "Connected Accounts", action: "See All") {
                path.append(HomeRoute.connectedAccounts)
            }

            let visibleAccounts = data.accounts.filter { !$0.isHidden }
            if visibleAccounts.isEmpty {
                Button {
                    path.append(HomeRoute.connectedAccounts)
                } label: {
                    VStack(spacing: AppTheme.spacingM) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.accentPrimary.opacity(0.8))
                        Text("Connect your accounts")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(theme.textSecondary)
                        Text("Link bank accounts, credit cards, and loans to see your full financial picture")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(theme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingXXL)
                    .background(theme.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(theme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
                }
                .buttonStyle(.plain)
            } else {
                dashboardGroupedAccounts(visibleAccounts)
            }
        }
    }

    private func dashboardGroupedAccounts(_ accounts: [Account]) -> some View {
        let categories: [(Account.CategoryGroup, Color)] = [
            (.checking, theme.accentGreen),
            (.savings, theme.accentGreen),
            (.creditCards, theme.accentRed),
            (.loans, theme.accentRed),
            (.investments, theme.accentGreen),
        ]
        return VStack(spacing: AppTheme.spacingXS) {
            ForEach(categories, id: \.0) { category, color in
                let catAccounts = accounts.filter { $0.categoryGroup == category }
                if !catAccounts.isEmpty {
                    dashboardCategoryRow(
                        category: category,
                        accounts: catAccounts,
                        color: color,
                        isExpanded: dashboardExpandedCategories.contains(category)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if dashboardExpandedCategories.contains(category) {
                                dashboardExpandedCategories.remove(category)
                            } else {
                                dashboardExpandedCategories.insert(category)
                            }
                        }
                    }
                }
            }
        }
        .background(theme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
    }

    private func dashboardCategoryRow(
        category: Account.CategoryGroup,
        accounts: [Account],
        color: Color,
        isExpanded: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        let total = accounts.reduce(0) { $0 + $1.displayBalance }
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                onTap()
            } label: {
                HStack {
                    Text(category.rawValue)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Text(formatCurrency(category == .creditCards || category == .loans ? -abs(total) : total))
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(color)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(AppTheme.spacingL)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    let grouped = Dictionary(grouping: accounts) { $0.institution ?? "Unknown" }
                    ForEach(Array(grouped.keys).sorted(), id: \.self) { institution in
                        if let instAccounts = grouped[institution] {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(institution)
                                    .font(AppTheme.Typography.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(theme.textSecondary)
                                ForEach(instAccounts) { account in
                                    HStack {
                                        Text(account.displayName)
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(theme.textPrimary)
                                        Spacer()
                                        Text(formatCurrency(account.displayBalance))
                                            .font(AppTheme.Typography.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(color)
                                    }
                                    .padding(.horizontal, AppTheme.spacingM)
                                    .padding(.vertical, AppTheme.spacingS)
                                }
                            }
                            .padding(.horizontal, AppTheme.spacingL)
                            .padding(.bottom, AppTheme.spacingS)
                        }
                    }
                }
                .padding(.bottom, AppTheme.spacingM)
            }
        }
    }
    
    private func accountGroupIcon(_ group: Account.AccountGroup) -> String {
        switch group {
        case .cash: return "dollarsign"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .credit: return "creditcard.fill"
        case .loans: return "doc.text.fill"
        }
    }
    
    private var budgetSnapshot: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            SectionHeader(title: "Budgets", action: "View All") {
                path.append(HomeRoute.budgets)
            }
            ForEach(fullBudgets.prefix(3)) { budget in
                Button {
                    path.append(HomeRoute.budget(budget.id))
                } label: {
                    VStack(spacing: 0) {
                        BudgetProgressBar(budget: budget, compact: true)
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(theme.textTertiary)
                                .padding(.trailing, AppTheme.spacingS)
                                .padding(.bottom, AppTheme.spacingXS)
                        }
                    }
                    .padding(AppTheme.spacingL)
                    .background(theme.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(theme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var goalsProgress: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            SectionHeader(title: "Goals", action: "View All") {
                path.append(HomeRoute.goals)
            }
            ForEach(fullGoals.prefix(3)) { goal in
                Button {
                    path.append(HomeRoute.goal(goal.id))
                } label: {
                    HStack(spacing: AppTheme.spacingL) {
                        ProgressRing(progress: goal.progress, lineWidth: 6, size: 44, color: theme.accentGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.name)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(theme.textPrimary)
                            Text("\(Int(goal.progress * 100))% complete")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(theme.textSecondary.opacity(0.9))
                        }
                        Spacer()
                        Text(formatCurrency(goal.currentAmount))
                            .font(AppTheme.Typography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.accentGreen)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(AppTheme.spacingL)
                    .background(theme.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(theme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var fullBudgets: [Budget] {
        data.budgets + [
            Budget(id: UUID(uuidString: "00000000-0000-0000-0000-000000000101") ?? UUID(), category: "Shopping", limit: 600, spent: 422, period: .monthly),
            Budget(id: UUID(uuidString: "00000000-0000-0000-0000-000000000102") ?? UUID(), category: "Housing", limit: 2200, spent: 2200, period: .monthly),
            Budget(id: UUID(uuidString: "00000000-0000-0000-0000-000000000103") ?? UUID(), category: "Utilities", limit: 260, spent: 174, period: .monthly),
            Budget(id: UUID(uuidString: "00000000-0000-0000-0000-000000000104") ?? UUID(), category: "Entertainment", limit: 320, spent: 210, period: .monthly),
        ]
    }

    private var fullGoals: [Goal] {
        data.goals + [
            Goal(id: UUID(uuidString: "00000000-0000-0000-0000-000000000201") ?? UUID(), name: "New Laptop", targetAmount: 2400, currentAmount: 920, targetDate: Calendar.current.date(byAdding: .month, value: 5, to: Date())),
            Goal(id: UUID(uuidString: "00000000-0000-0000-0000-000000000202") ?? UUID(), name: "Debt Payoff", targetAmount: 8600, currentAmount: 1800, targetDate: Calendar.current.date(byAdding: .month, value: 12, to: Date())),
        ]
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private var netWorthDeltaValue: Double {
        guard data.netWorthHistory.count >= 2 else { return 0 }
        return data.netWorthHistory[data.netWorthHistory.count - 1].1 - data.netWorthHistory[data.netWorthHistory.count - 2].1
    }
    
    private var monthlySpendingDeltaValue: Double {
        guard data.monthlySpendingHistory.count >= 2 else { return 0 }
        return data.monthlySpendingHistory[data.monthlySpendingHistory.count - 1].1 - data.monthlySpendingHistory[data.monthlySpendingHistory.count - 2].1
    }
    
    private func refresh() async {
        let previousNetWorth = data.netWorth
        // Refresh from Plaid first, then fetch from Supabase
        if let session = try? await SupabaseService.shared.client.auth.session {
            _ = try? await PlaidService.shared.refreshAccounts(authToken: session.accessToken)
        }
        await data.fetchAll()
        let newNetWorth = data.netWorth
        let change = abs(newNetWorth - previousNetWorth)
        let significantChange = change > 500 || (previousNetWorth > 0 && change / previousNetWorth > 0.05)
        if significantChange {
            await MainActor.run { appState.allowNetWorthAnimationAgain = true }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
