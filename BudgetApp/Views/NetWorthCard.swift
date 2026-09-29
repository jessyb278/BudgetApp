import SwiftUI
import Charts

// MARK: - Time Range

enum NetWorthTimeRange: String, CaseIterable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    
    var months: Int {
        switch self {
        case .oneMonth: return 1
        case .threeMonths: return 3
        case .oneYear: return 12
        }
    }
}

// MARK: - Net Worth Card (Smart, Layered)

struct NetWorthCard: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var appState: AppState
    let netWorth: Double
    let changeAmount: Double
    let history: [(Date, Double)]
    let insight: String
    let historyForRange: (Int) -> [(Date, Double)]
    var onTap: (() -> Void)?
    
    @State private var animatedValue: Double = 0
    @State private var chartProgress: Double = 0
    @State private var selectedRange: NetWorthTimeRange = .threeMonths
    @State private var isPressed = false
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    private var displayedHistory: [(Date, Double)] {
        historyForRange(selectedRange.months)
    }
    
    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: 0) {
            // TOP: Header + main value (compact, no extra padding)
            HStack {
                Text("Net Worth")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                changeBadge
            }
            .frame(height: AppTheme.DashboardCard.headerHeight)

            Text(formatCurrency(animatedValue))
                .font(AppTheme.Typography.title)
                .foregroundStyle(theme.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 4)

            HStack(spacing: AppTheme.spacingS) {
                ForEach(NetWorthTimeRange.allCases, id: \.rawValue) { range in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(spring) { selectedRange = range }
                    } label: {
                        Text(range.rawValue)
                            .font(AppTheme.Typography.captionSmall)
                            .foregroundStyle(selectedRange == range ? .white : theme.textSecondary)
                            .padding(.horizontal, AppTheme.spacingM)
                            .padding(.vertical, AppTheme.spacingXS)
                            .background(selectedRange == range ? theme.accentPrimary : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, AppTheme.DashboardCard.elementSpacing)

            // MIDDLE: Chart (flexible, top-aligned)
            NetWorthChart(data: displayedHistory, progress: chartProgress)
                .frame(height: 45)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppTheme.DashboardCard.elementSpacing)

            Spacer(minLength: AppTheme.DashboardCard.sectionSpacing)

            // BOTTOM: Footer (pinned)
            VStack(alignment: .leading, spacing: AppTheme.DashboardCard.elementSpacing) {
                Text(insight)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(theme.textSecondary.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                HStack(spacing: AppTheme.spacingXS) {
                    Text("View breakdown")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(theme.accentPrimary)
            }
            .frame(height: AppTheme.DashboardCard.footerHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .scaleEffect(isPressed ? 0.97 : 1)
        
        Group {
            if let onTap {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(spring) { isPressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(spring) { isPressed = false }
                        onTap()
                    }
                } label: { cardContent }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .onAppear {
            runNetWorthAnimationIfNeeded()
        }
        .onChange(of: appState.allowNetWorthAnimationAgain) { _, allowAgain in
            if allowAgain { runNetWorthAnimationIfNeeded() }
        }
        .onChange(of: selectedRange) { _, _ in
            withAnimation(spring) { chartProgress = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.6)) { chartProgress = 1 }
            }
        }
    }
    
    private var changeBadge: some View {
        Text(formatSignedCurrency(changeAmount))
            .font(AppTheme.Typography.captionSmall)
            .foregroundStyle(changeAmount >= 0 ? theme.accentGreen : theme.accentRed)
            .padding(.horizontal, AppTheme.spacingS)
            .padding(.vertical, AppTheme.spacingXS)
            .background((changeAmount >= 0 ? theme.accentGreen : theme.accentRed).opacity(theme.badgeBackgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS))
    }
    
    private func runNetWorthAnimationIfNeeded() {
        let shouldAnimate = !appState.hasAnimatedNetWorth || appState.allowNetWorthAnimationAgain
        if shouldAnimate {
            animatedValue = 0
            withAnimation(.easeOut(duration: 0.8)) {
                animatedValue = netWorth
            }
            animateChart()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                appState.hasAnimatedNetWorth = true
                appState.allowNetWorthAnimationAgain = false
            }
        } else {
            animatedValue = netWorth
            chartProgress = 1
        }
    }
    
    private func animateChart() {
        withAnimation(.easeOut(duration: 0.7)) { chartProgress = 1 }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatSignedCurrency(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(formatCurrency(abs(value)))"
    }
}

// MARK: - Net Worth Chart

struct NetWorthChart: View {
    @Environment(\.theme) private var theme
    let data: [(Date, Double)]
    var progress: Double = 1
    
    var body: some View {
        if data.isEmpty {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surfacePrimary.opacity(0.4))
                .frame(height: 45)
        } else {
            Chart(data, id: \.0) { item in
                    AreaMark(
                        x: .value("Date", item.0),
                        y: .value("Value", item.1)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary.opacity(0.35), theme.accentPrimary.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.0),
                        y: .value("Value", item.1)
                    )
                    .foregroundStyle(theme.accentPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(theme.textTertiary)
                    }
                }
                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(theme.textTertiary) } }
                .mask(
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: geo.size.width * progress)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .frame(height: 45)
        }
    }
}

// MARK: - Detail Screens

struct NetWorthDetailScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared

    private var visibleAccounts: [Account] {
        data.accounts.filter { !$0.isHidden }
    }
    private var assetAccounts: [Account] {
        visibleAccounts.filter { $0.classification == .asset }
    }
    private var liabilityAccounts: [Account] {
        visibleAccounts.filter { $0.classification == .liability }
    }
    private var assets: Double {
        assetAccounts.reduce(0) { $0 + $1.netWorthBalance }
    }
    private var liabilities: Double {
        abs(liabilityAccounts.reduce(0) { $0 + $1.netWorthBalance })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                Text(formatCurrency(data.netWorth))
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(theme.textPrimary)
                HStack(spacing: AppTheme.spacingL) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assets")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                        Text(formatCurrency(assets))
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(theme.accentGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.spacingL)
                    .background(theme.accentGreen.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Liabilities")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                        Text(formatCurrency(liabilities))
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(theme.accentRed)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.spacingL)
                    .background(theme.accentRed.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                if !assetAccounts.isEmpty {
                    sectionHeader("Assets", color: theme.accentGreen)
                    ForEach(assetAccounts) { account in
                        accountRow(account, color: theme.accentGreen)
                    }
                }
                if !liabilityAccounts.isEmpty {
                    sectionHeader("Liabilities", color: theme.accentRed)
                    ForEach(liabilityAccounts) { account in
                        accountRow(account, color: theme.accentRed)
                    }
                }
            }
            .padding(AppTheme.spacingXXL)
            .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Net Worth")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(AppTheme.Typography.headline)
            .foregroundStyle(theme.textPrimary)
            .padding(.top, AppTheme.spacingM)
    }

    private func accountRow(_ account: Account, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(theme.textPrimary)
                if let inst = account.institution, !inst.isEmpty {
                    Text(inst)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
            Text(formatCurrency(account.displayBalance))
                .font(AppTheme.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(AppTheme.spacingL)
        .background(theme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct SpendingDetailScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                Text("Monthly Spending")
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(theme.textPrimary)
                Text(formatCurrency(data.monthlySpending))
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(theme.accentPrimary)
            }
            .padding(AppTheme.spacingXXL)
            .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Spending")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct CreditScoreDetailScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXL) {
                CreditScoreDial(score: data.creditScore, width: 200, isVisible: true, showsTitle: true)
                Text(data.creditScoreKeyFactor)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(AppTheme.spacingXXL)
            .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Credit Score")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct InsightsHubScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingM) {
                ForEach(data.insights) { insight in
                    InsightCard(insight: insight)
                }
            }
            .padding(AppTheme.spacingXXL)
            .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

#Preview {
    let cal = Calendar.current
    let history = (0..<12).compactMap { i -> (Date, Double)? in
        cal.date(byAdding: .month, value: -11 + i, to: cal.startOfMonth(for: Date())).map { ($0, 25000 + Double(i) * 300) }
    }
    ZStack {
        ThemeColors.dark.backgroundPrimary.ignoresSafeArea()
        NetWorthCard(
            netWorth: 28610,
            changeAmount: 2946,
            history: history,
            insight: "Your net worth growth accelerated this month",
            historyForRange: { _ in history }
        )
        .environmentObject(AppState())
        .padding()
    }
}
