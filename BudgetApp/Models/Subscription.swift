import Foundation

struct Subscription: Identifiable {
    let id: UUID
    let merchant: Merchant
    let amount: Double
    let frequency: SubscriptionFrequency
    let nextChargeDate: Date?
    enum SubscriptionFrequency: String, CaseIterable { case weekly, monthly, yearly }
}
