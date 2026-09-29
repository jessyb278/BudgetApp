import SwiftUI

struct MerchantRow: View {
    @Environment(\.theme) private var theme
    let transaction: Transaction
    var showCategory: Bool = true
    var onTap: (() -> Void)?
    
    var body: some View {
        Group {
            if onTap != nil {
                Button { onTap?() } label: { rowContent }
            } else {
                rowContent
            }
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: AppTheme.spacingM) {
            MerchantLogo(merchant: transaction.merchant, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant.displayName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(theme.textPrimary)
                if showCategory {
                    Text(transaction.category)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.textSecondary.opacity(0.9))
                }
            }
            Spacer()
            Text(formatAmount(transaction.amount))
                .font(AppTheme.Typography.headline)
                .foregroundStyle(transaction.isExpense ? theme.textPrimary : theme.accentGreen)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, AppTheme.spacingL)
        .background(theme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        let str = f.string(from: NSNumber(value: abs(amount))) ?? "$0"
        return amount < 0 ? "-\(str)" : str
    }
}
