import SwiftUI

struct InsightCard: View {
    let insight: Insight
    var body: some View {
        HStack(spacing: AppTheme.spacing) {
            RoundedRectangle(cornerRadius: 4)
                .fill(insight.accentColor.opacity(0.3))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(insight.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}
