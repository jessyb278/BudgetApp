import SwiftUI

// MARK: - Message Model

private struct Message: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    
    enum Role {
        case user
        case ai
    }
}

// MARK: - AI Assistant View (Premium Glassmorphism)

struct AIAssistantView: View {
    @Environment(\.theme) private var theme
    var onDismiss: (() -> Void)? = nil
    @State private var messages: [Message] = []
    @State private var inputText = ""
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    private let blue = Color(hex: "6366F1")
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // BACKGROUND (layered, textured, rich)
            ZStack {
                theme.backgroundPrimary
                if theme.isDarkMode {
                    LinearGradient(
                        colors: [
                            theme.accentPrimary.opacity(0.1),
                            theme.accentPrimary.opacity(0.02),
                            blue.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [
                            theme.accentPrimary.opacity(0.08),
                            theme.accentPrimary.opacity(0.03),
                            .clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.35),
                        startRadius: 0,
                        endRadius: 400
                    )
                } else {
                    // Light mode: very subtle warm tint only
                    RadialGradient(
                        colors: [
                            theme.accentPrimary.opacity(0.015),
                            .clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.3),
                        startRadius: 0,
                        endRadius: 300
                    )
                }
                NoiseTextureView(opacity: theme.isDarkMode ? 0.04 : 0.015)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER (Clean + Techy)
                HStack(alignment: .top, spacing: AppTheme.spacingM) {
                    if let onDismiss {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(theme.textSecondary.opacity(0.8))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        HStack(spacing: AppTheme.spacingS) {
                            Text("AI Assistant")
                                .font(AppTheme.Typography.largeTitle)
                                .foregroundStyle(theme.textPrimary)
                            
                            Text("BETA")
                                .font(AppTheme.Typography.captionSmall)
                                .foregroundStyle(.white)
                                .padding(.horizontal, AppTheme.spacingS)
                                .padding(.vertical, AppTheme.spacingXS)
                                .background(theme.accentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS))
                        }
                        
                        Text("Understand your money instantly")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(theme.textSecondary)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.top, AppTheme.spacingL)
                .padding(.bottom, AppTheme.spacingM)
                
                // CHAT AREA
                ScrollView {
                    VStack(spacing: AppTheme.spacingL) {
                        if messages.isEmpty {
                            Spacer(minLength: AppTheme.spacingXXL)
                            
                            VStack(spacing: AppTheme.spacingS) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    theme.accentPrimary.opacity(theme.isDarkMode ? 0.35 : 0.18),
                                                    theme.accentPrimary.opacity(theme.isDarkMode ? 0.12 : 0.06),
                                                    .clear
                                                ],
                                                center: .center,
                                                startRadius: 24,
                                                endRadius: 90
                                            )
                                        )
                                        .frame(width: 180, height: 180)
                                        .blur(radius: 24)
                                    AnimatedSparkleIcon(size: 56, glowRadius: 32)
                                }
                                
                                Text("How can I help?")
                                    .font(AppTheme.Typography.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(theme.textPrimary)
                                
                                Text("Ask about spending, budgets, or trends")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(theme.textSecondary.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, AppTheme.spacingXXL)
                            
                            Spacer(minLength: AppTheme.spacingXXL)
                        } else {
                            ForEach(messages) { message in
                                HStack(alignment: .top, spacing: AppTheme.spacingM) {
                                    if message.role == .ai {
                                        Text(message.text)
                                            .font(AppTheme.Typography.body)
                                            .foregroundStyle(theme.textPrimary)
                                            .padding(AppTheme.spacingM)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                                    .fill(.ultraThinMaterial)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                                    .stroke(theme.borderSubtle, lineWidth: 1)
                                            )
                                        Spacer(minLength: 48)
                                    } else {
                                        Spacer(minLength: 48)
                                        Text(message.text)
                                            .font(AppTheme.Typography.body)
                                            .foregroundStyle(.white)
                                            .padding(AppTheme.spacingM)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .background(
                                                LinearGradient(
                                                    colors: [theme.accentPrimary, blue],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                                    }
                                }
                                .padding(.horizontal, AppTheme.spacingXL)
                            }
                        }
                    }
                    .padding(.vertical, AppTheme.spacingL)
                    .padding(.bottom, AppTheme.tabBarHeight + 80)
                }
                .scrollIndicators(.hidden)
            }
            
            // INPUT BAR (anchored above safe area)
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, theme.backgroundPrimary.opacity(theme.isDarkMode ? 0.3 : 0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)
                
                HStack(spacing: AppTheme.spacingS) {
                    TextField("Ask anything...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, AppTheme.spacingM)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(theme.borderSubtle, lineWidth: 1)
                        )
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(Circle())
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, AppTheme.spacingM)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusL))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusL)
                        .stroke(theme.borderSubtle, lineWidth: 1)
                )
            }
            .padding(.horizontal, AppTheme.spacingXL)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AppTheme.spacingXXL)
            }
        }
    }
    
    // MARK: - Message Handling
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        withAnimation(spring) {
            messages.append(Message(role: .user, text: text))
        }
        inputText = ""
        respond(to: text)
    }
    
    // MARK: - Hardcoded AI Responses
    
    private func respond(to input: String) {
        let response: String
        
        if input.lowercased().contains("subscription") {
            response = "You have 2 subscriptions totaling $50/month. Canceling unused ones could save you $27."
        } else if input.lowercased().contains("save") {
            response = "You could reduce food spending and subscriptions to save around $120/month."
        } else if input.lowercased().contains("spend") {
            response = "Your highest spending category is Food, followed by Transport."
        } else if input.lowercased().contains("compare") {
            response = "You spent 18% more this month compared to last month."
        } else {
            response = "Based on your data, you're on track, but small adjustments could improve savings."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(spring) {
                messages.append(Message(role: .ai, text: response))
            }
        }
    }
}

// MARK: - Noise Texture (subtle depth)

private struct NoiseTextureView: View {
    var opacity: Double = 0.048
    
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 4
            var x: CGFloat = 0
            while x < size.width + step {
                var y: CGFloat = 0
                while y < size.height + step {
                    let hash = Int(x * 7 + y * 13) % 100
                    let gray = 0.15 + Double(hash) / 120
                    context.fill(
                        Path(CGRect(x: x, y: y, width: step, height: step)),
                        with: .color(.white.opacity(gray * opacity))
                    )
                    y += step
                }
                x += step
            }
        }
        .drawingGroup()
        .allowsHitTesting(false)
    }
}

#Preview {
    AIAssistantView()
}
