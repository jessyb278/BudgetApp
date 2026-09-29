import Foundation

struct Goal: Identifiable {
    let id: UUID
    let name: String
    let targetAmount: Double
    var currentAmount: Double
    let targetDate: Date?
    var progress: Double { min(1, currentAmount / targetAmount) }
}
