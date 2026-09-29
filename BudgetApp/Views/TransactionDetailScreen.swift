import SwiftUI

struct TransactionDetailScreen: View {
    @Environment(\.theme) private var theme
    let transaction: Transaction
    @StateObject private var data = SupabaseDataService.shared
    @State private var isRecurring: Bool = false
    @State private var noteText = "Coffee with teammate after planning session."
    @State private var tags = ["Work", "Food"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXXL) {
                headerSection
                detailsSection
                actionsSection
            }
            .padding(AppTheme.spacingXXL)
            .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(transaction.merchant.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
        .onAppear { isRecurring = transaction.isRecurring }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.spacingL) {
            MerchantLogo(merchant: transaction.merchant, size: 64)
            
            Text(formatAmount(transaction.amount))
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(transaction.isExpense ? theme.textPrimary : theme.accentGreen)
            
            Text(transaction.category)
                .font(AppTheme.Typography.body)
                .foregroundStyle(theme.textSecondary)

            if transaction.isRecurring || isRecurring {
                Text("Recurring")
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, AppTheme.spacingS)
                    .padding(.vertical, AppTheme.spacingXS)
                    .background(AppTheme.accentPurple)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacingXXL)
        .background(theme.surfacePrimary)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(theme.borderSubtle, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
    }
    
    private var detailsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                detailRow("Merchant", transaction.merchant.displayName)
                detailRow("Category", transaction.category)
                detailRow("Account Used", accountName(for: transaction.accountId))
                detailRow("Date & Time", formatDateTime(transaction.date))
                if transaction.isRecurring || isRecurring {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        Text("Recurring details")
                            .font(AppTheme.Typography.captionSmall)
                            .foregroundStyle(theme.textSecondary)
                        Text("Detected monthly cadence. Next expected around \(nextRecurringDate).")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundStyle(theme.textPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text("Transaction note")
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(theme.textSecondary)
                    Text(noteText)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(theme.textPrimary)
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text("Tags / Labels")
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(theme.textSecondary)
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(AppTheme.Typography.captionSmall)
                                .foregroundStyle(theme.textSecondary)
                                .padding(.horizontal, AppTheme.spacingS)
                                .padding(.vertical, AppTheme.spacingXS)
                                .background(theme.surfaceSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        CardView {
            VStack(spacing: AppTheme.spacingS) {
                actionRow("Categorize")
                actionRow("Add Note")
                Button {
                    isRecurring.toggle()
                } label: {
                    actionRowLabel(transaction.isRecurring || isRecurring ? "Already Recurring" : "Mark as Recurring")
                }
                .buttonStyle(.plain)
                actionRow("View Similar Transactions")
            }
        }
    }
    
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.bodySmall)
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(theme.textPrimary)
        }
    }

    private func actionRow(_ title: String) -> some View {
        actionRowLabel(title)
    }

    private func actionRowLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(theme.textTertiary)
        }
    }
    
    private func accountName(for id: UUID) -> String {
        data.accounts.first { $0.id == id }?.name ?? "Unknown"
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        let val = amount < 0 ? -amount : amount
        let str = f.string(from: NSNumber(value: val)) ?? "$0"
        return amount < 0 ? "-\(str)" : str
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private var nextRecurringDate: String {
        let next = Calendar.current.date(byAdding: .day, value: 28, to: transaction.date) ?? Date()
        return next.formatted(date: .abbreviated, time: .omitted)
    }
}
