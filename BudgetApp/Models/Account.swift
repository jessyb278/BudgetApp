import Foundation

struct Account: Identifiable {
    let id: UUID
    let name: String
    let type: AccountType
    let balance: Double
    let institution: String?
    let subtype: String?
    let classification: AccountClassification
    let categoryGroup: CategoryGroup
    var includeInNetWorth: Bool
    var customName: String?
    var isHidden: Bool

    /// Spec category_group: Checking, Savings, Credit Cards, Loans, Investments
    enum CategoryGroup: String {
        case checking = "Checking"
        case savings = "Savings"
        case creditCards = "Credit Cards"
        case loans = "Loans"
        case investments = "Investments"

        static func from(_ raw: String?) -> CategoryGroup {
            guard let r = raw?.trimmingCharacters(in: .whitespaces), !r.isEmpty else { return .checking }
            switch r {
            case "Savings": return .savings
            case "Credit Cards": return .creditCards
            case "Loans": return .loans
            case "Investments": return .investments
            default: return .checking
            }
        }
    }

    enum AccountType: String, CaseIterable {
        case checking, savings, creditCard, loan, brokerage
        case depository, investment, credit
    }

    enum AccountClassification: String {
        case asset
        case liability
    }

    enum AccountGroup: String {
        case cash
        case investments
        case credit
        case loans
    }

    /// User-facing group: Cash, Investments, Credit, Loans (derived from categoryGroup)
    var accountGroup: AccountGroup {
        switch categoryGroup {
        case .creditCards: return .credit
        case .loans: return .loans
        case .investments: return .investments
        case .checking, .savings: return .cash
        }
    }

    /// User-facing subtype label: Checking, Savings, Brokerage, Credit Card, etc.
    var accountSubtypeLabel: String {
        let st = (subtype ?? "").lowercased()
        let t = (type.rawValue).lowercased()
        if st.contains("checking") || (t == "depository" || t == "checking") && st.isEmpty { return "Checking" }
        if st.contains("savings") || t == "savings" { return "Savings" }
        if st.contains("brokerage") || t == "brokerage" { return "Brokerage" }
        if st.contains("401") || st.contains("ira") || st.contains("retirement") { return "Retirement" }
        if t == "credit" || st.contains("credit") { return "Credit Card" }
        if st.contains("student") { return "Student Loan" }
        if st.contains("mortgage") { return "Mortgage" }
        if st.contains("auto") { return "Auto Loan" }
        if st.contains("personal") { return "Personal Loan" }
        if t == "loan" { return "Loan" }
        if t == "investment" { return "Investment" }
        return "Account"
    }

    /// Display name: custom name if set, else institution name
    var displayName: String { customName ?? name }

    /// Balance for display: liabilities shown as positive (debt owed)
    var displayBalance: Double {
        if classification == .liability {
            return abs(balance)
        }
        return balance
    }

    /// Balance for net worth: assets positive, liabilities negative
    var netWorthBalance: Double {
        guard includeInNetWorth, !isHidden else { return 0 }
        if classification == .liability { return -abs(balance) }
        return balance
    }

    init(
        id: UUID,
        name: String,
        type: AccountType,
        balance: Double,
        institution: String?,
        subtype: String? = nil,
        classification: AccountClassification = .asset,
        categoryGroup: CategoryGroup = .checking,
        includeInNetWorth: Bool = true,
        customName: String? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.institution = institution
        self.subtype = subtype
        self.classification = classification
        self.categoryGroup = categoryGroup
        self.includeInNetWorth = includeInNetWorth
        self.customName = customName
        self.isHidden = isHidden
    }
}
