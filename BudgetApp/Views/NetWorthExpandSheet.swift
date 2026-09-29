import SwiftUI

// MARK: - Net Worth Expand Sheet

struct NetWorthExpandSheet: View {
    @Environment(\.theme) private var theme
    let netWorth: Double
    let accounts: [Account]
    let onDismiss: () -> Void
    
    private var assets: Double {
        accounts.filter { $0.classification == .asset }.reduce(0) { $0 + $1.netWorthBalance }
    }
    
    private var liabilities: Double {
        abs(accounts.filter { $0.classification == .liability }.reduce(0) { $0 + $1.netWorthBalance })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Net Worth")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.textSecondary)
                        Text(formatCurrency(netWorth))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                    }
                    
                    // Assets vs Liabilities
                    HStack(spacing: 16) {
                        breakdownCard(title: "Assets", value: assets, color: theme.accentGreen)
                        breakdownCard(title: "Liabilities", value: liabilities, color: theme.accentRed)
                    }
                    
                    // Account breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account Breakdown")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                        ForEach(accounts) { account in
                            HStack {
                                Text(account.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Text(formatCurrency(account.displayBalance))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(account.classification == .asset ? theme.accentGreen : theme.accentRed)
                            }
                            .padding(16)
                            .background(theme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundStyle(theme.accentPrimary)
                }
            }
        }
    }
    
    private func breakdownCard(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            Text(formatCurrency(value))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}
