import SwiftUI
import Charts

// MARK: - Smart Spending Card (Behavior-Focused)

struct SmartSpendingCard: View {
    @Environment(\.theme) private var theme
    let monthlySpending: Double
    let changeAmount: Double
    let history: [(Date, Double)]
    let direction: String  // "up", "down", "stable"
    let threeMonthAverage: Double
    let paceOnTrack: Bool
    let topCategory: (String, Double)?
    var onTap: (() -> Void)?
    
    @State private var animatedValue: Double = 0
    @State private var chartProgress: Double = 0
    @State private var isPressed = false
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    private var directionText: String {
        switch direction {
        case "up": return "Spending is trending upward"
        case "down": return "Spending is trending downward"
        default: return "Spending is stable"
        }
    }
    
    private var comparisonText: String? {
        guard threeMonthAverage > 0 else { return nil }
        let pct = ((monthlySpending - threeMonthAverage) / threeMonthAverage) * 100
        if abs(pct) < 3 { return nil }
        if pct > 0 {
            return "Higher than your 3‑month average"
        } else {
            return "Lower than your 3‑month average"
        }
    }
    
    private var paceText: String {
        paceOnTrack ? "You're on track to stay within budget" : "Consider slowing spending to stay on budget"
    }
    
    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: 0) {
            // TOP: Header + main value (compact)
            HStack {
                Text("Monthly Spending")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(formatSignedCurrency(changeAmount))
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(changeAmount <= 0 ? theme.accentGreen : theme.accentOrange)
                    .padding(.horizontal, AppTheme.spacingS)
                    .padding(.vertical, AppTheme.spacingXS)
                    .background((changeAmount <= 0 ? theme.accentGreen : theme.accentOrange).opacity(theme.badgeBackgroundOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS))
            }
            .frame(height: AppTheme.DashboardCard.headerHeight)

            Text(formatCurrency(animatedValue))
                .font(AppTheme.Typography.title)
                .foregroundStyle(theme.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 4)

            Text(paceText)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(paceOnTrack ? theme.accentGreen : theme.accentAmber)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.top, AppTheme.DashboardCard.elementSpacing)

            // MIDDLE: Chart (flexible, top-aligned)
            Chart(history, id: \.0) { item in
                AreaMark(
                    x: .value("Date", item.0),
                    y: .value("Value", item.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentTeal.opacity(0.35), theme.accentTeal.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                LineMark(x: .value("Date", item.0), y: .value("Value", item.1))
                    .foregroundStyle(theme.accentTeal)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .month)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated)).foregroundStyle(theme.textTertiary) } }
            .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(theme.textTertiary) } }
            .frame(height: 42)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppTheme.DashboardCard.elementSpacing)
            .opacity(chartProgress)

            Spacer(minLength: AppTheme.DashboardCard.sectionSpacing)

            // BOTTOM: Footer (pinned)
            VStack(alignment: .leading, spacing: AppTheme.DashboardCard.elementSpacing) {
                Text(directionText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(theme.textSecondary.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                HStack(spacing: AppTheme.spacingXS) {
                    Text("View spending")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(theme.accentTeal)
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
            animateValue()
            withAnimation(.easeOut(duration: 0.6)) { chartProgress = 1 }
        }
    }
    
    private func animateValue() {
        let steps = 24
        let increment = monthlySpending / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03 * Double(i)) {
                withAnimation(.easeOut(duration: 0.02)) {
                    animatedValue = min(animatedValue + increment, monthlySpending)
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatSignedCurrency(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : "-"
        return "\(prefix)\(formatCurrency(abs(value)))"
    }
}
