import SwiftUI

// MARK: - Tab Item

struct TabItem: Identifiable {
    let id: Int
    let icon: String
    let label: String
}

// MARK: - Bottom Nav Bar (5-tab floating design)

struct BottomNavBar: View {
    @Environment(\.theme) private var theme
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    
    @State private var tappedTab: Int? = nil
    @State private var aiBreathingScale: CGFloat = 0.97
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    private let aiTabId = 2
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                if tab.id == aiTabId {
                    aiTabButton(for: tab)
                } else {
                    standardTabButton(for: tab)
                }
            }
        }
        .padding(.horizontal, AppTheme.spacingL)
        .frame(height: 60)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusL))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: theme.isDarkMode ? .black.opacity(0.2) : .black.opacity(0.06), radius: theme.isDarkMode ? 12 : 8, y: 4)
        .onAppear { updateBreathingAnimation() }
        .onChange(of: selectedTab) { _, _ in updateBreathingAnimation() }
    }
    
    private func updateBreathingAnimation() {
        if selectedTab == aiTabId {
            aiBreathingScale = 0.98
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                aiBreathingScale = 1.02
            }
        } else {
            aiBreathingScale = 1.0
        }
    }
    
    private func standardTabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab.id
        let isTapped = tappedTab == tab.id
        
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(spring) { tappedTab = tab.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(spring) {
                    selectedTab = tab.id
                    tappedTab = nil
                }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.accentPrimary.opacity(0.25),
                                        theme.accentPrimary.opacity(0.15)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? theme.accentPrimary : theme.textSecondary.opacity(0.85))
                        .scaleEffect(isTapped ? 0.95 : 1)
                }
                .frame(height: 32)
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.accentPrimary : theme.textSecondary.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    private func aiTabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab.id
        let isTapped = tappedTab == tab.id
        
        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(spring) { tappedTab = tab.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(spring) {
                    selectedTab = tab.id
                    tappedTab = nil
                }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Gradient background + subtle glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accentPrimary,
                                    Color(hex: "6366F1"),
                                    Color(hex: "3B82F6")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: theme.accentPrimary.opacity(0.4), radius: 8)
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(isTapped ? 0.9 : (aiBreathingScale * 1.15))
                }
                .frame(height: 48)
                .offset(y: -6)
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.accentPrimary : theme.textSecondary.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab View Container (smooth fade transitions)

struct CustomTabView<Content: View>: View {
    @Binding var selectedTab: Int
    var displayedTab: Int? = nil
    let tabs: [TabItem]
    @ViewBuilder let content: (Int) -> Content
    
    private var effectiveDisplayTab: Int {
        displayedTab ?? selectedTab
    }
    
    var body: some View {
        ZStack {
            content(effectiveDisplayTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: AppTheme.tabBarHeight)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
                .zIndex(0)
            
            VStack(spacing: 0) {
                Spacer()
                Spacer().frame(height: AppTheme.spacingM)
                
                BottomNavBar(selectedTab: $selectedTab, tabs: tabs)
                    .padding(.horizontal, AppTheme.spacingL)
                    .padding(.bottom, AppTheme.spacingS)
            }
            .zIndex(5)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected = 0
        var body: some View {
            ZStack {
                ThemeColors.dark.backgroundPrimary.ignoresSafeArea()
                CustomTabView(selectedTab: $selected, tabs: [
                    TabItem(id: 0, icon: "house.fill", label: "Home"),
                    TabItem(id: 1, icon: "list.bullet", label: "Activity"),
                    TabItem(id: 2, icon: "sparkles", label: "AI"),
                    TabItem(id: 3, icon: "chart.line.uptrend.xyaxis", label: "Plan"),
                    TabItem(id: 4, icon: "ellipsis.circle.fill", label: "More"),
                ]) { tab in
                    Text("Tab \(tab)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(.white)
                }
            }
        }
    }
    return PreviewWrapper()
}
