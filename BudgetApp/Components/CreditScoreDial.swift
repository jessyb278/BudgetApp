import SwiftUI

private struct CreditScoreGaugeMetrics {
    let center: CGPoint
    let radius: CGFloat
    
    static func make(in size: CGSize, strokeWidth: CGFloat) -> CreditScoreGaugeMetrics {
        let radius = min(size.width, size.height * 2) / 2 - strokeWidth / 2
        let center = CGPoint(x: size.width / 2, y: size.height - strokeWidth / 2)
        return CreditScoreGaugeMetrics(center: center, radius: radius)
    }
}

private struct CreditScoreGaugeArc: Shape {
    var progress: Double
    var strokeWidth: CGFloat
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(1, max(0, progress))
        guard clampedProgress > 0 else { return Path() }
        
        let metrics = CreditScoreGaugeMetrics.make(in: rect.size, strokeWidth: strokeWidth)
        let startAngle = Double.pi
        let endAngle = Double.pi - (clampedProgress * Double.pi)
        let steps = max(2, Int(ceil(clampedProgress * 120)))
        
        var path = Path()
        
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let angle = startAngle + ((endAngle - startAngle) * t)
            let point = CGPoint(
                x: metrics.center.x + metrics.radius * CGFloat(cos(angle)),
                y: metrics.center.y - metrics.radius * CGFloat(sin(angle))
            )
            
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        return path
    }
}

/// Premium credit score gauge — top semicircle arc (LEFT→TOP→RIGHT).
/// Animates from 300 to score on first appearance. Experian / Credit Karma quality.
struct CreditScoreDial: View {
    @Environment(\.theme) private var theme
    let score: Int
    var width: CGFloat = 280
    var isVisible: Bool = true
    var showsTitle: Bool = true
    
    private let minScore = 300
    private let maxScore = 850
    private let lineWidth: CGFloat = 22
    
    @State private var hasAnimated = false
    @State private var displayedScore: Double = 300
    @State private var showCompletionGlow = false
    
    private let animationDuration: Double = 1.5
    private let initialDelay: Double = 0.3
    
    private var targetScore: Double {
        min(Double(maxScore), max(Double(minScore), Double(score)))
    }
    
    private var animatedScore: Int {
        Int(displayedScore.rounded())
    }
    
    private var gaugeProgress: Double {
        min(1, max(0, (displayedScore - Double(minScore)) / Double(maxScore - minScore)))
    }
    
    private var gaugeHeight: CGFloat {
        width / 2 + lineWidth
    }
    
    private var scoreLabel: String {
        switch Int(targetScore) {
        case 0..<580: return "Poor"
        case 580..<670: return "Fair"
        case 670..<740: return "Good"
        case 740..<800: return "Very Good"
        default: return "Exceptional"
        }
    }
    
    private var scoreColor: Color {
        if theme.isDarkMode {
            switch Int(targetScore) {
            case 0..<580: return Color(hex: "DC2626")
            case 580..<670: return Color(hex: "F97316")
            case 670..<740: return Color(hex: "EAB308")
            case 740..<800: return Color(hex: "22C55E")
            default: return Color(hex: "15803D")
            }
        } else {
            switch Int(targetScore) {
            case 0..<580: return Color(hex: "B91C1C")
            case 580..<670: return Color(hex: "C2410C")
            case 670..<740: return Color(hex: "A16207")
            case 740..<800: return Color(hex: "15803D")
            default: return Color(hex: "166534")
            }
        }
    }
    
    /// Left-to-right rainbow so the stroke reads red → green across the gauge.
    private var arcGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "DC2626"),
                Color(hex: "F97316"),
                Color(hex: "EAB308"),
                Color(hex: "22C55E"),
                Color(hex: "15803D")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    CreditScoreGaugeArc(progress: 1, strokeWidth: lineWidth)
                        .stroke(theme.surfaceSecondary, style: strokeStyle(cap: .round))
                    
                    CreditScoreGaugeArc(progress: 1, strokeWidth: lineWidth)
                        .stroke(arcGradient.opacity(theme.isDarkMode ? 0.18 : 0.25), style: strokeStyle(cap: .round))
                    
                    CreditScoreGaugeArc(progress: gaugeProgress, strokeWidth: lineWidth)
                        .stroke(arcGradient, style: strokeStyle(cap: .round))
                        .shadow(color: showCompletionGlow ? scoreColor.opacity(0.45) : .clear, radius: 8)
                    
                    VStack(spacing: 6) {
                        if showsTitle {
                            Text("Credit Score")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.textSecondary)
                        }
                        
                        Text("\(animatedScore)")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                            .contentTransition(.numericText())
                        
                        Text(scoreLabel)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(scoreColor)
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: showsTitle ? geometry.size.height * 0.24 : geometry.size.height * 0.18)
                }
            }
            .frame(width: width, height: gaugeHeight)
            
            // Min/max labels aligned with arc ends
            HStack(alignment: .center, spacing: 0) {
                Text("300")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text("850")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(width: width)
            .padding(.top, 12)
            .offset(y: 8)
        }
        .onChange(of: isVisible) { _, visible in
            if visible && !hasAnimated {
                triggerAnimation()
            }
        }
        .onAppear {
            if isVisible && !hasAnimated {
                triggerAnimation()
            }
        }
    }
    
    private func strokeStyle(cap: CGLineCap) -> StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: cap)
    }
    
    private func triggerAnimation() {
        hasAnimated = true
        displayedScore = Double(minScore)
        showCompletionGlow = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            withAnimation(.easeOut(duration: animationDuration)) {
                displayedScore = targetScore
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showCompletionGlow = true
                }
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Compact Credit Score Gauge (for dashboard cards)

enum CreditScoreGaugeSize {
    case compact
    case dashboard
}

/// Fixed-height gauge for dashboard cards. No overlap, strict layout.
struct CompactCreditScoreGauge: View {
    @Environment(\.theme) private var theme
    let score: Int
    var isVisible: Bool = true
    var size: CreditScoreGaugeSize = .compact

    private let minScore = 300
    private let maxScore = 850
    private var lineWidth: CGFloat { size == .dashboard ? 18 : 10 }
    private var gaugeWidth: CGFloat { size == .dashboard ? 280 : 120 }
    private var gaugeArcHeight: CGFloat { size == .dashboard ? 95 : 44 }

    @State private var displayedScore: Double = 300

    private var targetScore: Double {
        min(Double(maxScore), max(Double(minScore), Double(score)))
    }

    private var animatedScore: Int {
        Int(displayedScore.rounded())
    }

    private var gaugeProgress: Double {
        min(1, max(0, (displayedScore - Double(minScore)) / Double(maxScore - minScore)))
    }

    private var scoreLabel: String {
        switch Int(targetScore) {
        case 0..<580: return "Poor"
        case 580..<670: return "Fair"
        case 670..<740: return "Good"
        case 740..<800: return "Very Good"
        default: return "Exceptional"
        }
    }

    private var scoreColor: Color {
        switch Int(targetScore) {
        case 0..<580: return Color(hex: "DC2626")
        case 580..<670: return Color(hex: "F97316")
        case 670..<740: return Color(hex: "EAB308")
        case 740..<800: return Color(hex: "22C55E")
        default: return Color(hex: "15803D")
        }
    }

    private var arcGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "DC2626"),
                Color(hex: "F97316"),
                Color(hex: "EAB308"),
                Color(hex: "22C55E"),
                Color(hex: "15803D")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .center) {
                CreditScoreGaugeArc(progress: 1, strokeWidth: lineWidth)
                    .stroke(theme.surfaceSecondary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: gaugeWidth, height: gaugeArcHeight)

                CreditScoreGaugeArc(progress: 1, strokeWidth: lineWidth)
                    .stroke(arcGradient.opacity(0.25), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: gaugeWidth, height: gaugeArcHeight)

                CreditScoreGaugeArc(progress: gaugeProgress, strokeWidth: lineWidth)
                    .stroke(arcGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: gaugeWidth, height: gaugeArcHeight)

                VStack(spacing: 4) {
                    Text("\(animatedScore)")
                        .font(.system(size: size == .dashboard ? 52 : 24, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                        .contentTransition(.numericText())
                    Text(scoreLabel)
                        .font(.system(size: size == .dashboard ? 17 : 11, weight: .semibold))
                        .foregroundStyle(scoreColor)
                }
                .frame(width: gaugeWidth, height: gaugeArcHeight)
                .offset(y: size == .dashboard ? 12 : 0)
            }
            .frame(width: gaugeWidth, height: gaugeArcHeight)
            .frame(maxWidth: .infinity)

            HStack {
                Text("300")
                    .font(.system(size: size == .dashboard ? 14 : 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text("850")
                    .font(.system(size: size == .dashboard ? 14 : 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(width: gaugeWidth)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            if isVisible {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayedScore = targetScore
                }
            }
        }
        .onChange(of: isVisible) { _, visible in
            if visible {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayedScore = targetScore
                }
            }
        }
    }
}
