import SwiftUI

// MARK: - Quick Action

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    var onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(spring) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(spring) { isPressed = false }
                onTap?()
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.accentBlue)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 88, height: 80)
            .background(AppTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.textTertiary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Actions Scroll

struct QuickActionsScroll: View {
    let actions: [QuickAction]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(actions) { action in
                    QuickActionCard(
                        title: action.title,
                        icon: action.icon,
                        onTap: action.action
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.backgroundPrimary.ignoresSafeArea()
        QuickActionsScroll(actions: [
            QuickAction(title: "View subscriptions", icon: "repeat.circle.fill", action: {}),
            QuickAction(title: "Set budget", icon: "chart.pie.fill", action: {}),
            QuickAction(title: "Track spending", icon: "chart.bar.fill", action: {}),
            QuickAction(title: "Find savings", icon: "dollarsign.circle.fill", action: {}),
        ])
        .padding()
    }
}
