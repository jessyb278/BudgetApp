import SwiftUI
import Combine

@MainActor
final class MockDataService: ObservableObject {
    static let shared = MockDataService()
    
    @Published var transactions: [Transaction] = []
    @Published var accounts: [Account] = []
    @Published var budgets: [Budget] = []
    @Published var goals: [Goal] = []
    @Published var subscriptions: [Subscription] = []
    @Published var insights: [Insight] = []
    
    let creditScore = 643
    private let merchants: [String: Merchant]
    
    init() {
        self.merchants = Self.createMerchants()
        loadAllData()
    }
    
    var netWorth: Double { accounts.reduce(0) { $0 + $1.netWorthBalance } }
    
    var monthlySpending: Double {
        let cal = Calendar.current
        let monthStart = cal.startOfMonth(for: Date())
        return abs(transactions.filter { $0.date >= monthStart && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
    }
    
    var monthlySpendingHistory: [(Date, Double)] {
        let cal = Calendar.current
        var history: [(Date, Double)] = []
        for i in (0..<6).reversed() {
            guard let date = cal.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let monthStart = cal.startOfMonth(for: date)
            let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
            let spent = abs(transactions
                .filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount < 0 }
                .reduce(0) { $0 + $1.amount })
            history.append((monthStart, spent))
        }
        return history
    }
    
    var netWorthHistory: [(Date, Double)] {
        netWorthHistory(months: 12)
    }
    
    func netWorthHistory(months: Int) -> [(Date, Double)] {
        let cal = Calendar.current
        let baseNetWorth = 35000.0
        var history: [(Date, Double)] = []
        var running = baseNetWorth
        for i in (0..<months).reversed() {
            guard let date = cal.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let monthStart = cal.startOfMonth(for: date)
            let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
            let monthTxs = transactions.filter { $0.date >= monthStart && $0.date < monthEnd }
            running += monthTxs.reduce(0) { $0 + $1.amount }
            history.append((monthStart, running))
        }
        return history
    }
    
    var unreviewedTransactions: [Transaction] {
        transactions.filter { !$0.isReviewed }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Insight Strip (for dashboard)
    
    struct SpendingInsight {
        let message: String
        let type: InsightStripType
    }
    
    var spendingInsight: SpendingInsight? {
        let cal = Calendar.current
        guard let thisMonthStart = cal.date(byAdding: .month, value: 0, to: cal.startOfMonth(for: Date())),
              let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart),
              let thisMonthEnd = cal.date(byAdding: .month, value: 1, to: thisMonthStart),
              let lastMonthEnd = cal.date(byAdding: .month, value: 1, to: lastMonthStart) else { return nil }
        
        let thisMonthFood = abs(transactions
            .filter { $0.date >= thisMonthStart && $0.date < thisMonthEnd && $0.category == "Food" && $0.amount < 0 }
            .reduce(0) { $0 + $1.amount })
        let lastMonthFood = abs(transactions
            .filter { $0.date >= lastMonthStart && $0.date < lastMonthEnd && $0.category == "Food" && $0.amount < 0 }
            .reduce(0) { $0 + $1.amount })
        
        guard lastMonthFood > 0 else { return nil }
        let pct = ((thisMonthFood - lastMonthFood) / lastMonthFood) * 100
        
        if pct > 15 {
            return SpendingInsight(
                message: "You spent \(Int(pct))% more on food this month",
                type: InsightStripType.spendingWarning
            )
        } else if pct < -15 {
            return SpendingInsight(
                message: "You spent \(Int(abs(pct)))% less on food this month",
                type: InsightStripType.positiveReinforcement
            )
        }
        
        return SpendingInsight(
            message: "You could save $50 on subscriptions",
                type: InsightStripType.savingsOpportunity
        )
    }
    
    // MARK: - Single Rotating Insight (priority-based, ONE at a time)
    
    var primaryInsight: SpendingInsight? {
        spendingInsight
    }
    
    // MARK: - Spending Behavior
    var spendingThreeMonthAverage: Double {
        let cal = Calendar.current
        var total: Double = 0
        for i in 0..<3 {
            guard let monthStart = cal.date(byAdding: .month, value: -i, to: cal.startOfMonth(for: Date())),
                  let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let spent = abs(transactions
                .filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount < 0 }
                .reduce(0) { $0 + $1.amount })
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
        let byCategory = Dictionary(grouping: transactions.filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount < 0 }, by: { $0.category })
        let top = byCategory.map { ($0.key, abs($0.value.reduce(0) { $0 + $1.amount })) }.max(by: { $0.1 < $1.1 })
        return top
    }
    
    // MARK: - Plan Tab Data
    
    var monthlyIncome: Double {
        let cal = Calendar.current
        let monthStart = cal.startOfMonth(for: Date())
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
        return transactions.filter { $0.date >= monthStart && $0.date < monthEnd && $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    
    var monthlySavings: Double {
        max(0, monthlyIncome - monthlySpending)
    }
    
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
        let thisSpent = abs(transactions.filter { $0.date >= thisMonthStart && $0.date < thisMonthEnd && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        let lastSpent = abs(transactions.filter { $0.date >= lastMonthStart && $0.date < lastMonthEnd && $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        let thisRate = thisIncome > 0 ? (thisIncome - thisSpent) / thisIncome : 0
        let lastRate = lastIncome > 0 ? (lastIncome - lastSpent) / lastIncome : 0
        guard lastRate > 0 else { return 0 }
        return ((thisRate - lastRate) / lastRate) * 100
    }
    
    var totalDebt: Double {
        accounts.filter { $0.classification == .liability }.reduce(0) { $0 + abs($1.balance) }
    }
    
    struct PlanRecommendation: Identifiable {
        let id = UUID()
        let insight: String
        let potentialSavings: Double
    }
    
    var planRecommendations: [PlanRecommendation] {
        var recs: [PlanRecommendation] = []
        if let sub = subscriptions.first, subscriptions.count >= 2 {
            recs.append(PlanRecommendation(insight: "You have \(subscriptions.count) subscriptions. Consider canceling unused ones.", potentialSavings: 27))
        }
        if let top = topSpendingCategory, top.1 > 400 {
            recs.append(PlanRecommendation(insight: "\(top.0) is your top spending category. Set a limit to reduce.", potentialSavings: 80))
        }
        if spendingDirection == "up" {
            recs.append(PlanRecommendation(insight: "Spending is up this month. Review discretionary categories.", potentialSavings: 50))
        }
        return Array(recs.prefix(3))
    }
    
    func monthsToGoal(_ goal: Goal) -> Int? {
        let cal = Calendar.current
        let remaining = goal.targetAmount - goal.currentAmount
        guard remaining > 0 else { return 0 }
        let monthlySavingsForGoal = monthlySavings > 0 ? monthlySavings * 0.3 : 500
        let months = Int(ceil(remaining / monthlySavingsForGoal))
        return max(1, months)
    }
    
    // MARK: - Credit Score Guidance
    let creditScoreChange: Int = 12
    var creditScoreKeyFactor: String { "High utilization is limiting your score" }
    var creditScoreSuggestion: String { "Reducing utilization below 30% can improve your score" }
    
    // MARK: - Net Worth Insight
    var netWorthInsight: String {
        let h = netWorthHistory
        guard h.count >= 3 else { return "Tracking your net worth over time" }
        let recentChange = h[h.count - 1].1 - h[h.count - 2].1
        let priorChange = h[h.count - 2].1 - h[h.count - 3].1
        if recentChange > priorChange && recentChange > 0 {
            return "Your net worth growth accelerated this month"
        }
        if recentChange > 0 {
            return "Your net worth is trending upward"
        }
        return "Your net worth is stabilizing"
    }
    
    func markReviewed(_ transaction: Transaction) {
        if let idx = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[idx].isReviewed = true
        }
    }
    
    private func loadAllData() {
        accounts = Self.createAccounts()
        let accountIds = Dictionary(uniqueKeysWithValues: accounts.map { ($0.name, $0.id) })
        transactions = Self.createTransactions(merchants: merchants, accountIds: accountIds)
        budgets = Self.createBudgets(transactions: transactions)
        goals = Self.createGoals()
        subscriptions = Self.createSubscriptions(merchants: merchants)
        insights = Self.createInsights()
    }
    
    private static func createMerchants() -> [String: Merchant] {
        let list: [(String, String, Color, String)] = [
            ("uber", "Uber", AppTheme.accentBlue, "car.fill"),
            ("starbucks", "Starbucks", Color(hex: "00704A"), "cup.and.saucer.fill"),
            ("amazon", "Amazon", Color(hex: "FF9900"), "bag.fill"),
            ("netflix", "Netflix", Color(hex: "E50914"), "play.rectangle.fill"),
            ("spotify", "Spotify", Color(hex: "1DB954"), "music.note"),
            ("traderjoes", "Trader Joe's", Color(hex: "E31837"), "cart.fill"),
            ("shell", "Shell", Color(hex: "FFD700"), "fuelpump.fill"),
            ("target", "Target", Color(hex: "CC0000"), "target"),
            ("paycheck", "Direct Deposit", AppTheme.accentGreen, "banknote.fill"),
            ("rent", "Rent", AppTheme.textSecondary, "house.fill"),
            ("doordash", "DoorDash", Color(hex: "FF3008"), "takeoutbag.and.fork.and.knife"),
            ("venmo", "Venmo", Color(hex: "008CFF"), "dollarsign"),
        ]
        return Dictionary(uniqueKeysWithValues: list.map { ($0.0, Merchant(name: $0.0, displayName: $0.1, color: $0.2, icon: $0.3)) })
    }
    
    private static func createAccounts() -> [Account] {
        [
            Account(id: UUID(), name: "Chase Checking", type: .checking, balance: 12450, institution: "Chase", classification: .asset, categoryGroup: .checking),
            Account(id: UUID(), name: "Chase Savings", type: .savings, balance: 18500, institution: "Chase", classification: .asset, categoryGroup: .savings),
            Account(id: UUID(), name: "Chase Sapphire", type: .creditCard, balance: 2340, institution: "Chase", classification: .liability, categoryGroup: .creditCards),
        ]
    }
    
    private static func createTransactions(merchants: [String: Merchant], accountIds: [String: UUID]) -> [Transaction] {
        let cal = Calendar.current
        let checkingId = accountIds["Chase Checking"]!
        let sapphireId = accountIds["Chase Sapphire"]!
        let startDate = cal.date(byAdding: .day, value: -30, to: Date())!
        var txs: [Transaction] = []
        
        func tx(_ key: String, _ amt: Double, _ cat: String, _ dayOffset: Int, _ recurring: Bool = false) {
            guard let m = merchants[key] else { return }
            let date = cal.date(byAdding: .day, value: dayOffset, to: startDate)!
            txs.append(Transaction(id: UUID(), merchant: m, amount: amt, date: date, category: cat, accountId: amt > 0 ? checkingId : sapphireId, isRecurring: recurring, isReviewed: Bool.random(), notes: nil, transactionType: .purchase))
        }
        
        for dayOffset in 0..<30 {
            if dayOffset % 14 == 0 { tx("paycheck", 4200, "Income", dayOffset, true) }
            if dayOffset % 30 == 1 { tx("rent", -2200, "Housing", dayOffset, true) }
            if dayOffset % 3 == 0 { tx("uber", Double.random(in: (-35)...(-12)), "Transport", dayOffset) }
            if dayOffset % 4 == 1 { tx("starbucks", Double.random(in: (-8)...(-4)), "Food", dayOffset) }
            if dayOffset % 7 == 2 { tx("amazon", Double.random(in: (-120)...(-15)), "Shopping", dayOffset) }
            if dayOffset % 30 == 5 { tx("netflix", -15.99, "Subscriptions", dayOffset, true) }
            if dayOffset % 30 == 8 { tx("spotify", -10.99, "Subscriptions", dayOffset, true) }
            if dayOffset % 14 == 3 { tx("traderjoes", Double.random(in: (-95)...(-45)), "Food", dayOffset) }
            if dayOffset % 15 == 4 { tx("shell", Double.random(in: (-65)...(-45)), "Transport", dayOffset) }
            if dayOffset % 10 == 1 { tx("target", Double.random(in: (-80)...(-25)), "Shopping", dayOffset) }
            if dayOffset % 10 == 5 { tx("doordash", Double.random(in: (-45)...(-18)), "Food", dayOffset) }
        }
        return txs.sorted { $0.date > $1.date }
    }
    
    private static func createBudgets(transactions: [Transaction]) -> [Budget] {
        let cal = Calendar.current
        let monthStart = cal.startOfMonth(for: Date())
        let monthTxs = transactions.filter { $0.date >= monthStart && $0.amount < 0 }
        func spent(_ cat: String) -> Double { abs(monthTxs.filter { $0.category == cat }.reduce(0) { $0 + $1.amount }) }
        return [
            Budget(id: UUID(), category: "Food", limit: 800, spent: spent("Food"), period: .monthly),
            Budget(id: UUID(), category: "Transport", limit: 350, spent: spent("Transport"), period: .monthly),
            Budget(id: UUID(), category: "Subscriptions", limit: 150, spent: spent("Subscriptions"), period: .monthly),
        ]
    }
    
    private static func createGoals() -> [Goal] {
        let cal = Calendar.current
        return [
            Goal(id: UUID(), name: "Emergency Fund", targetAmount: 25000, currentAmount: 18500, targetDate: cal.date(byAdding: .month, value: 6, to: Date())),
            Goal(id: UUID(), name: "Vacation", targetAmount: 5000, currentAmount: 2100, targetDate: cal.date(byAdding: .month, value: 4, to: Date())),
        ]
    }
    
    private static func createSubscriptions(merchants: [String: Merchant]) -> [Subscription] {
        let cal = Calendar.current
        guard let netflix = merchants["netflix"], let spotify = merchants["spotify"] else { return [] }
        return [
            Subscription(id: UUID(), merchant: netflix, amount: 15.99, frequency: .monthly, nextChargeDate: cal.date(byAdding: .day, value: 5, to: Date())!),
            Subscription(id: UUID(), merchant: spotify, amount: 10.99, frequency: .monthly, nextChargeDate: cal.date(byAdding: .day, value: 8, to: Date())!),
        ]
    }
    
    private static func createInsights() -> [Insight] {
        [
            Insight(id: UUID(), title: "You spent less this week", subtitle: "Dining down 18%", type: .trend, accentColor: AppTheme.accentGreen),
            Insight(id: UUID(), title: "On track for savings goal", subtitle: "74% to emergency fund", type: .tip, accentColor: AppTheme.accentTeal),
        ]
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
