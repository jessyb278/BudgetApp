import Foundation

struct ProfileRecord: Codable {
    let id: UUID
    var email: String?
    var appearance: String?
    var currency: String?
    enum CodingKeys: String, CodingKey { case id, email, appearance, currency }
}

struct AccountRecord: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let type: String
    let balance: Double
    let institution: String?
    let last_sync: Date?
    let subtype: String?
    let classification: String?
    let category_group: String?
    let include_in_net_worth: Bool?
    let custom_name: String?
    let is_hidden: Bool?
}

struct TransactionRecord: Codable {
    let id: UUID
    let user_id: UUID
    let account_id: UUID
    let name: String
    let amount: Double
    let category: String
    let date: Date
    let is_recurring: Bool
    var is_reviewed: Bool
    let notes: String?
    let transaction_type: String?
}

struct BudgetRecord: Codable {
    let id: UUID
    let user_id: UUID
    let category: String
    let limit: Double
    var spent: Double
    let period: String
}

struct GoalRecord: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let target: Double
    var current: Double
    let target_date: Date?
}

struct SubscriptionRecord: Codable {
    let id: UUID
    let user_id: UUID
    let merchant: String
    let amount: Double
    let frequency: String
    let next_charge_date: Date?
}

struct InsightRecord: Codable {
    let id: UUID
    let user_id: UUID
    let title: String
    let subtitle: String
    let type: String
    let accent_color: String?
}
