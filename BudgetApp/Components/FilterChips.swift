import SwiftUI

struct FilterChip: View {
    @Environment(\.theme) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : theme.textSecondary)
                .padding(.horizontal, AppTheme.spacingL)
                .padding(.vertical, AppTheme.spacingS)
                .background(isSelected ? theme.accentPrimary : theme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS))
        }
        .buttonStyle(.plain)
    }
}
