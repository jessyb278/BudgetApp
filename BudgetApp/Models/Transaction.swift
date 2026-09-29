import Foundation

struct Transaction: Identifiable {
    let id: UUID
    let merchant: Merchant
    let amount: Double
    let date: Date
    let category: String
    let accountId: UUID
    let isRecurring: Bool
    var isReviewed: Bool
    var notes: String?
    let transactionType: TransactionType
    var isExpense: Bool { amount < 0 }

    /// Exclude from spending/budgets: transfers, credit payments, loan payments
    var isSpending: Bool {
        transactionType == .purchase
    }

    enum TransactionType: String {
        case purchase
        case transfer
        case payment
    }
}
