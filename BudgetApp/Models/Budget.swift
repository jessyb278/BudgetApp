import Foundation

struct Budget: Identifiable {
    let id: UUID
    let category: String
    let limit: Double
    var spent: Double
    let period: BudgetPeriod
    var remaining: Double { max(0, limit - spent) }
    var progress: Double { min(1, spent / limit) }
    enum BudgetPeriod: String { case monthly, weekly }
}
