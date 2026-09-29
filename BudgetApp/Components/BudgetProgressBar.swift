import SwiftUI

struct BudgetProgressBar: View {
    @Environment(\.theme) private var theme
    let budget: Budget
    var compact: Bool = false
    private var progressColor: Color {
        if budget.progress >= 1 { return theme.accentRed }
        if budget.progress >= 0.85 { return theme.accentAmber }
        return theme.accentGreen
    }
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? AppTheme.spacingXS : AppTheme.spacingS) {
            HStack {
                Text(budget.category)
                    .font(compact ? AppTheme.Typography.bodySmall : AppTheme.Typography.headline)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text("$\(Int(budget.spent)) / $\(Int(budget.limit))")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(theme.textSecondary.opacity(0.9))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(theme.surfaceSecondary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: geo.size.width * budget.progress)
                }
            }
            .frame(height: compact ? 5 : 6)
        }
    }
}
