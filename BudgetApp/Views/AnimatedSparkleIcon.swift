import SwiftUI

// MARK: - Animated Sparkle Icon

struct AnimatedSparkleIcon: View {
    @Environment(\.theme) private var theme
    var size: CGFloat = 56
    var glowRadius: CGFloat = 24
    
    @State private var sparkle1Phase: Double = 0
    @State private var sparkle2Phase: Double = 0
    @State private var sparkle3Phase: Double = 0
    @State private var parallaxOffset: CGSize = .zero
    @State private var breatheScale: CGFloat = 0.95
    
    private let blue = Color(hex: "6366F1")
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    var body: some View {
        ZStack {
            // Soft radial glow behind icon (reduced in light mode)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accentPrimary.opacity(theme.isDarkMode ? 0.4 : 0.2),
                            theme.accentPrimary.opacity(theme.isDarkMode ? 0.15 : 0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: glowRadius
                    )
                )
                .frame(width: glowRadius * 2, height: glowRadius * 2)
                .blur(radius: 8)
                .offset(parallaxOffset)
            
            // 3 sparkle elements - main + 2 accents
            ZStack {
                sparkleElement(phase: sparkle1Phase, scale: 0.4, offset: CGSize(width: 0, height: 0))
                sparkleElement(phase: sparkle2Phase, scale: 0.22, offset: CGSize(width: -10, height: -8))
                sparkleElement(phase: sparkle3Phase, scale: 0.22, offset: CGSize(width: 8, height: 6))
            }
            .scaleEffect(breatheScale)
            .offset(parallaxOffset)
        }
        .frame(width: size + 20, height: size + 20)
        .onAppear {
            startAnimations()
        }
    }
    
    private func sparkleElement(phase: Double, scale: CGFloat, offset: CGSize) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * scale, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [theme.accentPrimary, blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.6 + 0.4 * (0.5 + 0.5 * sin(phase)))
            .scaleEffect(0.95 + 0.1 * (0.5 + 0.5 * sin(phase * 1.2)))
            .rotationEffect(.degrees(phase * 15))
            .offset(offset)
    }
    
    private func startAnimations() {
        // Sparkle 1: rotation + opacity + scale
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0)) {
            sparkle1Phase = .pi * 2
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.2)) {
            sparkle2Phase = .pi * 2
        }
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true).delay(0.4)) {
            sparkle3Phase = .pi * 2
        }
        
        // Parallax: very slow movement
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            parallaxOffset = CGSize(width: 4, height: 3)
        }
        
        // Breathe: scale 0.95 ↔ 1.05, 2s loop
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            breatheScale = 1.05
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "0B1220").ignoresSafeArea()
        AnimatedSparkleIcon()
    }
}
