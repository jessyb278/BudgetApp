import SwiftUI

struct PlanScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared
    @State private var recommendationStates: [UUID: RecommendationActionState] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingXL) {
                    goalsSection
                    budgetsSection
                    recommendationsSection
                    projectionsSection
                    savingsRateSection
                    debtSection
                }
                .padding(AppTheme.spacingXXL)
                .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
            }
            .ignoresSafeArea(edges: .bottom)
            .background(theme.backgroundPrimary)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                Text("Goals")
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                NavigationLink("View All") {
                    GoalsListScreen(goals: allGoals)
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(theme.textSecondary)
            }

            ForEach(allGoals.prefix(2)) { goal in
                NavigationLink {
                    GoalDetailScreen(goal: goal)
                } label: {
                    CardView {
                        HStack(spacing: AppTheme.spacingL) {
                            ProgressRing(progress: goal.progress, lineWidth: 6, size: 46, color: theme.accentGreen)
                            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                Text(goal.name)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(theme.textPrimary)
                                Text("\(currency(goal.currentAmount)) / \(currency(goal.targetAmount))")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(theme.textSecondary)
                                Text("\(Int(goal.progress * 100))% complete • ~\(data.monthsToGoal(goal) ?? 4) months left")
                                    .font(AppTheme.Typography.captionSmall)
                                    .foregroundStyle(theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(theme.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var budgetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                Text("Budgets")
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                NavigationLink("View All") {
                    BudgetsListScreen(budgets: allBudgets, transactions: data.transactions)
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(theme.textSecondary)
            }

            ForEach(allBudgets.prefix(3)) { budget in
                NavigationLink {
                    BudgetDetailScreen(
                        budget: budget,
                        transactions: data.transactions.filter { $0.category == budget.category }
                    )
                } label: {
                    CardView {
                        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                            HStack {
                                Text(budget.category)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Text(statusText(for: budget).0)
                                    .font(AppTheme.Typography.captionSmall)
                                    .foregroundStyle(statusText(for: budget).1)
                            }
                            Text("\(currency(budget.spent)) / \(currency(budget.limit))")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(theme.textSecondary)
                            ProgressView(value: min(1, budget.progress))
                                .tint(statusText(for: budget).1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            SectionHeader(title: "Recommendations", action: nil)
            ForEach(recommendations.prefix(3)) { recommendation in
                NavigationLink {
                    RecommendationDetailScreen(
                        recommendation: recommendation,
                        actionState: recommendationBinding(for: recommendation.id)
                    )
                } label: {
                    CardView {
                        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                            HStack {
                                Text(recommendation.title)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(theme.textTertiary)
                            }
                            Text(recommendation.projectedBenefit)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(theme.accentGreen)
                            if recommendationStates[recommendation.id] == .applied {
                                Text("Applied")
                                    .font(AppTheme.Typography.captionSmall)
                                    .foregroundStyle(theme.accentPrimary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var projectionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            SectionHeader(title: "Projections", action: nil)
            NavigationLink {
                ProjectionsScreen()
            } label: {
                CardView {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        Text("Emergency fund projection")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(theme.textPrimary)
                        Text("At current pace, completion in about 4 months.")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(theme.textSecondary)
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(theme.textTertiary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var savingsRateSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            SectionHeader(title: "Savings Rate", action: nil)
            NavigationLink {
                SavingsRateDetailScreen()
            } label: {
                CardView {
                    HStack(spacing: AppTheme.spacingL) {
                        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                            Text(currency(data.monthlySavings))
                                .font(AppTheme.Typography.title)
                                .foregroundStyle(theme.accentGreen)
                            Text("Monthly savings")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: AppTheme.spacingXS) {
                            Text("\(Int(data.savingsRate * 100))%")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(theme.textPrimary)
                            Text("\(abs(Int(data.savingsRateChange)))% vs last month")
                                .font(AppTheme.Typography.captionSmall)
                                .foregroundStyle(data.savingsRateChange >= 0 ? theme.accentGreen : theme.accentRed)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(theme.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var debtSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                Text("Debt")
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                NavigationLink("Manage", destination: DebtOverviewScreen())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(theme.accentPrimary)
            }
            NavigationLink {
                DebtOverviewScreen()
            } label: {
                CardView {
                    HStack(spacing: AppTheme.spacingL) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(theme.accentRed.opacity(0.8))
                        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                            Text(currency(data.totalDebt))
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(theme.textPrimary)
                            Text("Total credit balance")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(theme.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var allBudgets: [Budget] {
        data.budgets + [
            Budget(id: UUID(uuidString: "00000000-0000-0000-0000-000000000301") ?? UUID(), category: "Shopping", limit: 600, spent: 422, period: .monthly),
            Budget(id: UUID(uuidString: "00000000-0000-0000-0000-000000000302") ?? UUID(), category: "Housing", limit: 2200, spent: 2200, period: .monthly),
            Budget(id: UUID(uuidString: "00000000-0000-0000-0000-000000000303") ?? UUID(), category: "Utilities", limit: 260, spent: 174, period: .monthly),
        ]
    }
    
    private var allGoals: [Goal] {
        data.goals + [
            Goal(id: UUID(uuidString: "00000000-0000-0000-0000-000000000401") ?? UUID(), name: "New Laptop", targetAmount: 2400, currentAmount: 920, targetDate: Calendar.current.date(byAdding: .month, value: 5, to: Date())),
            Goal(id: UUID(uuidString: "00000000-0000-0000-0000-000000000402") ?? UUID(), name: "Debt Payoff", targetAmount: 8600, currentAmount: 1800, targetDate: Calendar.current.date(byAdding: .month, value: 12, to: Date())),
        ]
    }
    
    private var recommendations: [PlanRecommendationItem] {
        [
            PlanRecommendationItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000501") ?? UUID(),
                title: "Cancel unused subscriptions",
                reason: "You have overlapping streaming subscriptions with low usage in the last 30 days.",
                projectedBenefit: "Projected savings: $26/month",
                linkedItems: ["Netflix", "Spotify"]
            ),
            PlanRecommendationItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000502") ?? UUID(),
                title: "Reduce dining spend",
                reason: "Food spending is 14% above your 3-month baseline.",
                projectedBenefit: "Projected savings: $120/month",
                linkedItems: ["Starbucks", "DoorDash", "Trader Joe's"]
            ),
            PlanRecommendationItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000503") ?? UUID(),
                title: "Increase monthly goal contribution",
                reason: "Emergency fund can complete 1 month earlier with a modest increase.",
                projectedBenefit: "Goal completion accelerated by 4 weeks",
                linkedItems: ["Emergency Fund"]
            ),
        ]
    }
    
    private func recommendationBinding(for id: UUID) -> Binding<RecommendationActionState> {
        Binding {
            recommendationStates[id] ?? .none
        } set: { newValue in
            recommendationStates[id] = newValue
        }
    }
    
    private func statusText(for budget: Budget) -> (String, Color) {
        if budget.progress >= 1 { return ("Over budget", theme.accentRed) }
        if budget.progress >= 0.85 { return ("Near limit", theme.accentAmber) }
        return ("On track", theme.accentGreen)
    }
    
    private func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Plan Screen Supporting Types

enum RecommendationActionState {
    case none, applied
}

struct PlanRecommendationItem: Identifiable {
    let id: UUID
    let title: String
    let reason: String
    let projectedBenefit: String
    let linkedItems: [String]
}

struct RecommendationDetailScreen: View {
    @Environment(\.theme) private var theme
    let recommendation: PlanRecommendationItem
    @Binding var actionState: RecommendationActionState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                Text(recommendation.reason)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(theme.textSecondary)
                Text(recommendation.projectedBenefit)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(theme.accentGreen)
                Button("Apply") { actionState = .applied }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accentPrimary)
            }
            .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(recommendation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct GoalsListScreen: View {
    @Environment(\.theme) private var theme
    let goals: [Goal]

    var body: some View {
        List {
            ForEach(goals) { goal in
                NavigationLink { GoalDetailScreen(goal: goal) } label: {
                    Text(goal.name)
                }
            }
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Goals")
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct GoalDetailScreen: View {
    @Environment(\.theme) private var theme
    let goal: Goal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                Text(goal.name)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(theme.textPrimary)
                Text("\(Int(goal.progress * 100))% complete")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(goal.name)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct BudgetsListScreen: View {
    @Environment(\.theme) private var theme
    let budgets: [Budget]
    let transactions: [Transaction]

    var body: some View {
        List {
            ForEach(budgets) { budget in
                NavigationLink {
                    BudgetDetailScreen(budget: budget, transactions: transactions.filter { $0.category == budget.category })
                } label: {
                    Text(budget.category)
                }
            }
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Budgets")
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct BudgetDetailScreen: View {
    @Environment(\.theme) private var theme
    let budget: Budget
    let transactions: [Transaction]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                BudgetProgressBar(budget: budget, compact: false)
                Text("\(Int(budget.progress * 100))% used")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(budget.category)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct ProjectionsScreen: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            Text("Emergency fund projection at current pace.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(theme.textSecondary)
                .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Projections")
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct SavingsRateDetailScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                Text("\(Int(data.savingsRate * 100))% savings rate")
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Savings Rate")
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct DebtOverviewScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared

    private func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                Text("Total debt: \(currency(data.totalDebt))")
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Debt")
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

#Preview {
    PlanScreen()
}
