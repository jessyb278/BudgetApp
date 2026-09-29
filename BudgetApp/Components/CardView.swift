import SwiftUI

struct CardView<Content: View>: View {
    @Environment(\.theme) private var theme
    let content: Content
    var elevated: Bool = false
    init(elevated: Bool = false, @ViewBuilder content: () -> Content) {
        self.elevated = elevated
        self.content = content()
    }
    var body: some View {
        content
            .padding(AppTheme.spacingL)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(elevated ? theme.surfaceSecondary : theme.surfacePrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}
