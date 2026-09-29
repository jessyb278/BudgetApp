import SwiftUI
import Charts

struct GraphContainer: View {
    let data: [(Date, Double)]
    var title: String? = nil
    var height: CGFloat = 140
    var accentColor: Color = AppTheme.accentBlue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Chart(data, id: \.0) { item in
                AreaMark(
                    x: .value("Date", item.0),
                    y: .value("Value", item.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor.opacity(0.5), accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Date", item.0),
                    y: .value("Value", item.1)
                )
                .foregroundStyle(accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .frame(height: height)
        }
    }
}
