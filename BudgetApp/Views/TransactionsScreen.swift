import SwiftUI

enum ActivitySegment: String, CaseIterable {
    case all = "All"
    case spending = "Spending"
    case income = "Income"
    case transfers = "Transfers"
    case recurring = "Recurring"
}

struct TransactionsScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared
    @State private var searchText = ""
    @State private var selectedChip: String = "All"
    @State private var selectedSegment: ActivitySegment = .all
    @State private var path = NavigationPath()
    @State private var hiddenTransactionIDs = Set<UUID>()
    
    private let chips = ["All", "Food", "Transport", "Shopping", "Housing", "Income", "Subscriptions", "Utilities"]
    
    private var filteredTransactions: [Transaction] {
        var txs = data.transactions.filter { !hiddenTransactionIDs.contains($0.id) }

        if selectedSegment != .all {
            switch selectedSegment {
            case .spending:
                txs = txs.filter { $0.amount < 0 }
            case .income:
                txs = txs.filter { $0.amount > 0 }
            case .transfers:
                txs = txs.filter { $0.category == "Transfer" || $0.merchant.displayName.contains("Transfer") }
            case .recurring:
                txs = txs.filter(\.isRecurring)
            case .all:
                break
            }
        }

        if selectedChip != "All" {
            txs = txs.filter { $0.category == selectedChip }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            txs = txs.filter {
                $0.merchant.displayName.localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query) ||
                String(format: "%.2f", abs($0.amount)).localizedCaseInsensitiveContains(query) ||
                ($0.isRecurring && "recurring".localizedCaseInsensitiveContains(query))
            }
        }

        return txs.sorted { $0.date > $1.date }
    }
    
    private var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions, by: groupKey(for:))
        let today = grouped["Today"] ?? []
        let yesterday = grouped["Yesterday"] ?? []
        let thisWeek = grouped["This Week"] ?? []
        let older = grouped.filter { !["Today", "Yesterday", "This Week"].contains($0.key) }
            .map { ($0.key, $0.value) }
            .sorted { parseDate($0.0) > parseDate($1.0) }
        var ordered: [(String, [Transaction])] = []
        if !today.isEmpty { ordered.append(("Today", today)) }
        if !yesterday.isEmpty { ordered.append(("Yesterday", yesterday)) }
        if !thisWeek.isEmpty { ordered.append(("This Week", thisWeek)) }
        ordered.append(contentsOf: older)
        return ordered
    }
    
    private func groupKey(for tx: Transaction) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(tx.date) { return "Today" }
        if cal.isDateInYesterday(tx.date) { return "Yesterday" }
        if cal.isDate(tx.date, equalTo: Date(), toGranularity: .weekOfYear) { return "This Week" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: tx.date)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingS) {
                        ForEach(chips, id: \.self) { chip in
                            FilterChip(title: chip, isSelected: selectedChip == chip) {
                                selectedChip = chip
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacingL)
                    .padding(.vertical, AppTheme.spacingS)
                }
                .background(theme.backgroundSecondary)

                Picker("Segment", selection: $selectedSegment) {
                    ForEach(ActivitySegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.spacingL)
                .padding(.vertical, AppTheme.spacingS)
                
                List {
                    ForEach(groupedTransactions, id: \.0) { group, txs in
                        Section {
                            ForEach(txs) { tx in
                                ActivityRow(
                                    transaction: tx,
                                    onRecurringTap: {
                                        path.append("recurring::\(tx.merchant.displayName)")
                                    }
                                )
                                .onTapGesture {
                                    path.append(tx.id)
                                }
                                .listRowBackground(theme.surfacePrimary)
                                .listRowSeparatorTint(theme.surfaceSecondary)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        Task { await data.markReviewed(tx) }
                                    } label: {
                                        Label("Mark Reviewed", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(theme.accentGreen)
                                    Button {
                                        hiddenTransactionIDs.insert(tx.id)
                                    } label: {
                                        Label("Hide", systemImage: "eye.slash.fill")
                                    }
                                    .tint(theme.accentOrange)
                                }
                            }
                        } header: {
                            Text(group)
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(theme.backgroundPrimary)
                .contentMargins(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL, for: .scrollContent)
            }
            .background(theme.backgroundPrimary)
            .searchable(text: $searchText, prompt: "Search merchant, category, amount, recurring")
            .navigationTitle("Activity")
            .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append("activity-filters")
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(theme.accentPrimary)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let tx = data.transactions.first(where: { $0.id == id }) {
                    TransactionDetailScreen(transaction: tx)
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "activity-filters" {
                    ActivityFiltersScreen()
                } else {
                    RecurringChargesScreen(
                        transactions: data.transactions,
                        focusedMerchant: value.replacingOccurrences(of: "recurring::", with: "")
                    )
                }
            }
        }
    }

    private func parseDate(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.date(from: value) ?? .distantPast
    }
}

private struct ActivityRow: View {
    @Environment(\.theme) private var theme
    let transaction: Transaction
    var onRecurringTap: (() -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            MerchantLogo(merchant: transaction.merchant, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant.displayName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(theme.textPrimary)
                HStack(spacing: AppTheme.spacingS) {
                    Text(transaction.category)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.textSecondary)
                    Text(transaction.amount > 0 ? "Chase Checking" : "Chase Sapphire")
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(theme.textTertiary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(transaction.amount))
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(transaction.amount < 0 ? theme.textPrimary : theme.accentGreen)
                if transaction.isRecurring {
                    Button("Recurring") {
                        onRecurringTap?()
                    }
                    .buttonStyle(.plain)
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.spacingS)
                    .padding(.vertical, AppTheme.spacingXS)
                    .background(AppTheme.accentPurple)
                    .clipShape(Capsule())
                }
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.textTertiary)
        }
        .padding(.vertical, AppTheme.spacingXS)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        let text = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0"
        return amount < 0 ? "-\(text)" : text
    }
}

struct ActivityFiltersScreen: View {
    @Environment(\.theme) private var theme

    var body: some View {
        List {
            Text("Filter by date range")
            Text("Filter by category")
            Text("Filter by amount")
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Filters")
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct RecurringChargesScreen: View {
    @Environment(\.theme) private var theme
    let transactions: [Transaction]
    let focusedMerchant: String

    private var filtered: [Transaction] {
        transactions.filter { $0.merchant.displayName == focusedMerchant }
    }

    var body: some View {
        List {
            ForEach(filtered) { tx in
                HStack {
                    Text(tx.merchant.displayName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Text(formatAmount(tx.amount))
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(tx.amount < 0 ? theme.textPrimary : theme.accentGreen)
                }
            }
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(focusedMerchant)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }

    private func formatAmount(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
