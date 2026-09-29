import SwiftUI

// MARK: - Suggestion Pill

struct SuggestionPill: View {
    let text: String
    let index: Int
    var isVisible: Bool = true
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var hasAppeared = false
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(spring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(spring) {
                    isPressed = false
                }
                onTap()
            }
        } label: {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .tracking(0.3)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        Color(hex: "1C2438")
                        LinearGradient(
                            colors: [
                                .white.opacity(isPressed ? 0.08 : 0.04),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "8B5CF6").opacity(0.25), lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(
                    color: .black.opacity(isPressed ? 0.4 : 0.2),
                    radius: isPressed ? 12 : 6,
                    y: isPressed ? 4 : 2
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
        .onAppear {
            withAnimation(spring.delay(Double(index) * 0.04)) {
                hasAppeared = true
            }
        }
        .onChange(of: isVisible) { _, visible in
            if !visible {
                withAnimation(spring) {
                    hasAppeared = false
                }
            }
        }
    }
}

// MARK: - Suggestion Pills Grid

struct SuggestionPillsGrid: View {
    let suggestions: [String]
    var isVisible: Bool = true
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        FlowLayout(spacing: 14) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, text in
                SuggestionPill(
                    text: text,
                    index: index,
                    isVisible: isVisible,
                    onTap: { onSuggestionTap(text) }
                )
            }
        }
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 24)
    }
}

// MARK: - Flow Layout (intelligent wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let proposedWidth = proposal.width ?? .infinity
        let maxWidth = proposedWidth.isFinite ? proposedWidth : 400
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    ZStack {
        Color(hex: "0B1220").ignoresSafeArea()
        SuggestionPillsGrid(
            suggestions: [
                "Where did I spend the most?",
                "Analyze my subscriptions",
                "How can I save money?",
            ],
            onSuggestionTap: { _ in }
        )
    }
}
