import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
final class SupabaseDataService: ObservableObject {
    static let shared = SupabaseDataService()

    @Published var transactions: [Transaction] = []
    @Published var accounts: [Account] = []
    @Published var budgets: [Budget] = []
    @Published var goals: [Goal] = []
    @Published var subscriptions: [Subscription] = []
    @Published var insights: [Insight] = []
    @Published var profile: ProfileRecord?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let creditScore = 643
    private let client = SupabaseService.shared.client

    private init() {}

    var currentUserId: UUID? { client.auth.currentSession?.user.id }

    var netWorth: Double { accounts.reduce(0) { $0 + $1.netWorthBalance } }

    var monthlySpending: Double {
        let cal = Calendar.current
        let monthStart = cal.startOfMonth(for: Date())
        return abs(spendingTransactions.filter { $0.date >= monthStart && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
    }

    /// Transactions that count toward spending (excludes transfers, credit/loan payments)
    private var spendingTransactions: [Transaction] {
        transactions.filter { $0.isSpending }
    }

    var monthlySpendingHistory: [(Date, Double)] {
        let cal = Calendar.current
        return (0..<6).reversed().compactMap { i -> (Date, Double)? in
            guard let date = cal.date(byAdding: .month, value: -i, to: Date()) else { return nil }
            let monthStart = cal.startOfMonth(for: date)
            let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
            let spent = abs(spendingTransactions.filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
            return (monthStart, spent)
        }
    }

    var netWorthHistory: [(Date, Double)] { netWorthHistory(months: 12) }

    func netWorthHistory(months: Int) -> [(Date, Double)] {
        let cal = Calendar.current
        var running = 0.0
        return (0..<months).reversed().compactMap { i -> (Date, Double)? in
            guard let date = cal.date(byAdding: .month, value: -i, to: Date()) else { return nil }
            let monthStart = cal.startOfMonth(for: date)
            let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
            running += transactions.filter { $0.date >= monthStart && $0.date < monthEnd }.reduce(0) { $0 + $1.amount }
            return (monthStart, running)
        }
    }

    var unreviewedTransactions: [Transaction] {
        transactions.filter { !$0.isReviewed }.sorted { $0.date > $1.date }
    }

    var primaryInsight: (message: String, type: InsightStripType)? {
        guard let i = insights.first else { return nil }
        let stripType: InsightStripType
        switch i.type {
        case .trend: stripType = .positiveReinforcement
        case .anomaly: stripType = .spendingWarning
        case .summary: stripType = .positiveReinforcement
        case .tip: stripType = .savingsOpportunity
        }
        return (i.subtitle, stripType)
    }

    var netWorthInsight: String {
        let h = netWorthHistory
        guard h.count >= 3 else { return "Tracking your net worth over time" }
        let recentChange = h[h.count - 1].1 - h[h.count - 2].1
        let priorChange = h[h.count - 2].1 - h[h.count - 3].1
        if recentChange > priorChange && recentChange > 0 { return "Your net worth growth accelerated this month" }
        if recentChange > 0 { return "Your net worth is trending upward" }
        return "Your net worth is stabilizing"
    }

    var spendingThreeMonthAverage: Double {
        let cal = Calendar.current
        var total: Double = 0
        for i in 0..<3 {
            guard let monthStart = cal.date(byAdding: .month, value: -i, to: cal.startOfMonth(for: Date())),
                  let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let spent = abs(spendingTransactions.filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
            total += spent
        }
        return total / 3
    }

    var spendingDirection: String {
        let current = monthlySpending
        let avg = spendingThreeMonthAverage
        guard avg > 0 else { return "neutral" }
        let pct = ((current - avg) / avg) * 100
        if pct > 5 { return "up" }
        if pct < -5 { return "down" }
        return "stable"
    }

    var spendingPaceOnTrack: Bool {
        let totalBudget = budgets.reduce(0) { $0 + $1.limit }
        guard totalBudget > 0 else { return true }
        let spent = budgets.reduce(0) { $0 + $1.spent }
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let dayOfMonth = Calendar.current.component(.day, from: Date())
        let expectedPace = totalBudget * (Double(dayOfMonth) / Double(daysInMonth))
        return spent <= expectedPace * 1.1
    }

    var topSpendingCategory: (String, Double)? {
        let cal = Calendar.current
        let monthStart = cal.startOfMonth(for: Date())
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
        let byCategory = Dictionary(grouping: spendingTransactions.filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount < 0 }, by: { $0.category })
        let top = byCategory.map { ($0.key, abs($0.value.reduce(0) { $0 + $1.amount })) }.max(by: { $0.1 < $1.1 })
        return top
    }

    let creditScoreChange: Int = 12
    var creditScoreKeyFactor: String { "High utilization is limiting your score" }
    var creditScoreSuggestion: String { "Reducing utilization below 30% can improve your score" }

    var monthlyIncome: Double {
        let cal = Calendar.current
        let monthStart = cal.startOfMonth(for: Date())
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
        return transactions.filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }

    var monthlySavings: Double { max(0, monthlyIncome - monthlySpending) }

    var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        return monthlySavings / monthlyIncome
    }

    var savingsRateChange: Double {
        let cal = Calendar.current
        guard let thisMonthStart = cal.date(byAdding: .month, value: 0, to: cal.startOfMonth(for: Date())),
              let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart),
              let thisMonthEnd = cal.date(byAdding: .month, value: 1, to: thisMonthStart),
              let lastMonthEnd = cal.date(byAdding: .month, value: 1, to: lastMonthStart) else { return 0 }
        let thisIncome = transactions.filter { $0.date >= thisMonthStart && $0.date < thisMonthEnd && $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let lastIncome = transactions.filter { $0.date >= lastMonthStart && $0.date < lastMonthEnd && $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let thisSpent = abs(spendingTransactions.filter { $0.date >= thisMonthStart && $0.date < thisMonthEnd && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        let lastSpent = abs(spendingTransactions.filter { $0.date >= lastMonthStart && $0.date < lastMonthEnd && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        let thisRate = thisIncome > 0 ? (thisIncome - thisSpent) / thisIncome : 0
        let lastRate = lastIncome > 0 ? (lastIncome - lastSpent) / lastIncome : 0
        guard lastRate > 0 else { return 0 }
        return ((thisRate - lastRate) / lastRate) * 100
    }

    var totalDebt: Double { accounts.filter { $0.classification == .liability }.reduce(0) { $0 + abs($1.balance) } }

    func monthsToGoal(_ goal: Goal) -> Int? {
        let remaining = goal.targetAmount - goal.currentAmount
        guard remaining > 0 else { return 0 }
        let monthlySavingsForGoal = monthlySavings > 0 ? monthlySavings * 0.3 : 500
        let months = Int(ceil(remaining / monthlySavingsForGoal))
        return max(1, months)
    }

    func fetchAll() async {
        guard currentUserId != nil else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await fetchTransactions()
            try await fetchAccounts()
            try await fetchBudgets()
            try await fetchGoals()
            try await fetchSubscriptions()
            try await fetchInsights()
            try await fetchProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchTransactions() async throws {
        let records: [TransactionRecord] = try await client.from("transactions").select().order("date", ascending: false).execute().value
        transactions = records.map { r in
            let txType: Transaction.TransactionType = {
                switch (r.transaction_type ?? "purchase").lowercased() {
                case "transfer": return .transfer
                case "payment": return .payment
                default: return .purchase
                }
            }()
            return Transaction(
                id: r.id,
                merchant: Merchant.from(name: r.name),
                amount: r.amount,
                date: r.date,
                category: r.category,
                accountId: r.account_id,
                isRecurring: r.is_recurring,
                isReviewed: r.is_reviewed,
                notes: r.notes,
                transactionType: txType
            )
        }
    }

    private func deriveCategoryGroup(type: String, subtype: String?) -> String {
        let t = type.lowercased()
        let st = (subtype ?? "").lowercased()
        if t == "credit" { return "Credit Cards" }
        if t == "loan" { return "Loans" }
        if t == "investment" || st.contains("brokerage") || st.contains("401") || st.contains("ira") || st.contains("retirement") { return "Investments" }
        if st.contains("savings") { return "Savings" }
        return "Checking"
    }

    func fetchAccounts() async throws {
        let records: [AccountRecord] = try await client.from("accounts").select().execute().value
        accounts = records.map { r in
            let plaidType = (r.type).lowercased()
            let mappedType: Account.AccountType = {
                if plaidType == "credit" { return .credit }
                if plaidType == "loan" { return .loan }
                if plaidType == "investment" { return .brokerage }
                if plaidType == "depository" {
                    let st = (r.subtype ?? "").lowercased()
                    if st.contains("savings") { return .savings }
                    return .checking
                }
                return Account.AccountType(rawValue: r.type) ?? .checking
            }()
            let classification: Account.AccountClassification = (r.classification ?? "asset").lowercased() == "liability" ? .liability : .asset
            let categoryGroup: Account.CategoryGroup = r.category_group != nil
                ? Account.CategoryGroup.from(r.category_group)
                : Account.CategoryGroup.from(deriveCategoryGroup(type: r.type, subtype: r.subtype))
            return Account(
                id: r.id,
                name: r.name,
                type: mappedType,
                balance: r.balance,
                institution: r.institution,
                subtype: r.subtype,
                classification: classification,
                categoryGroup: categoryGroup,
                includeInNetWorth: r.include_in_net_worth ?? true,
                customName: r.custom_name,
                isHidden: r.is_hidden ?? false
            )
        }
    }

    func fetchBudgets() async throws {
        let records: [BudgetRecord] = try await client.from("budgets").select().execute().value
        budgets = records.map { r in
            Budget(
                id: r.id,
                category: r.category,
                limit: r.limit,
                spent: r.spent,
                period: r.period == "weekly" ? .weekly : .monthly
            )
        }
    }

    func fetchGoals() async throws {
        let records: [GoalRecord] = try await client.from("goals").select().execute().value
        goals = records.map { r in
            Goal(
                id: r.id,
                name: r.name,
                targetAmount: r.target,
                currentAmount: r.current,
                targetDate: r.target_date
            )
        }
    }

    func fetchSubscriptions() async throws {
        let records: [SubscriptionRecord] = try await client.from("subscriptions").select().execute().value
        subscriptions = records.map { r in
            Subscription(
                id: r.id,
                merchant: Merchant.from(name: r.merchant),
                amount: r.amount,
                frequency: r.frequency == "weekly" ? .weekly : (r.frequency == "yearly" ? .yearly : .monthly),
                nextChargeDate: r.next_charge_date
            )
        }
    }

    func fetchInsights() async throws {
        let records: [InsightRecord] = try await client.from("insights").select().execute().value
        insights = records.map { r in
            let it: Insight.InsightType
            switch r.type {
            case "trend": it = .trend
            case "anomaly": it = .anomaly
            case "summary": it = .summary
            default: it = .tip
            }
            return Insight(
                id: r.id,
                title: r.title,
                subtitle: r.subtitle,
                type: it,
                accentColor: Color(hex: r.accent_color ?? "8B5CF6")
            )
        }
    }

    func fetchProfile() async throws {
        guard let uid = currentUserId else { return }
        let records: [ProfileRecord] = try await client.from("profiles").select().eq("id", value: uid.uuidString).execute().value
        profile = records.first
    }

    func markReviewed(_ transaction: Transaction) async {
        do {
            try await client.from("transactions").update(["is_reviewed": true]).eq("id", value: transaction.id.uuidString).execute()
            if let idx = transactions.firstIndex(where: { $0.id == transaction.id }) {
                var t = transactions[idx]
                t.isReviewed = true
                transactions[idx] = t
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleAccountIncludeInNetWorth(_ account: Account) async {
        do {
            let newValue = !account.includeInNetWorth
            try await client.from("accounts").update(["include_in_net_worth": newValue]).eq("id", value: account.id.uuidString).execute()
            if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
                var a = accounts[idx]
                a.includeInNetWorth = newValue
                accounts[idx] = a
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameAccount(_ account: Account, to name: String) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await client.from("accounts").update(["custom_name": name.trimmingCharacters(in: .whitespaces)]).eq("id", value: account.id.uuidString).execute()
            if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
                var a = accounts[idx]
                a.customName = name.trimmingCharacters(in: .whitespaces)
                accounts[idx] = a
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func hideAccount(_ account: Account) async {
        do {
            try await client.from("accounts").update(["is_hidden": true]).eq("id", value: account.id.uuidString).execute()
            if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
                var a = accounts[idx]
                a.isHidden = true
                accounts[idx] = a
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

