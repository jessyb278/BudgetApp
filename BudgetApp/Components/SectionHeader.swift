import SwiftUI

struct SectionHeader: View {
    @Environment(\.theme) private var theme
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)?
    var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            if let action = action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }
}
