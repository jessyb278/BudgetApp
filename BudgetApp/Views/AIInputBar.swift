import SwiftUI

// MARK: - AI Input Bar Theme

private enum AIInputTheme {
    static let purple = Color(hex: "8B5CF6")
    static let blue = Color(hex: "6366F1")
    static let inputBg = Color(hex: "1C2438")
    static let placeholderOpacity: Double = 0.4
    static let micDefaultOpacity: Double = 0.5
    static let micGlowOpacity: Double = 0.7
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - AI Input Bar

struct AIInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var isLoading: Bool = false
    var onSend: () -> Void
    var onMicTap: (() -> Void)?
    
    @State private var isMicPressed = false
    @State private var isSendPressed = false
    @State private var isListening = false
    @State private var micPulsePhase: Double = 0
    @State private var loadingRotation: Double = 0
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    private var showLoadingSpinner: Bool {
        isLoading
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Faint purple glow
            RoundedRectangle(cornerRadius: 24)
                .fill(AIInputTheme.purple.opacity(0.12))
                .blur(radius: 16)
                .frame(height: 64)
                .offset(y: 2)
            
            // Input container + send button
            HStack(alignment: .bottom, spacing: 0) {
                inputContainer
                Spacer().frame(width: 38)
            }
            .padding(.horizontal, 16)
            
            // Send button (floating, slightly overlaps input)
            sendButton
                .offset(x: -16, y: -4)
        }
        .onChange(of: isListening) { _, listening in
            if listening {
                startMicPulse()
            }
        }
    }
    
    // MARK: - Input Container
    
    private var inputContainer: some View {
        HStack(alignment: .bottom, spacing: 0) {
            TextField("", text: $text, axis: .vertical)
                .focused($isFocused)
                .placeholder(when: text.isEmpty) {
                    Text("Ask about your finances...")
                        .foregroundStyle(.white.opacity(AIInputTheme.placeholderOpacity))
                        .tracking(0.5)
                        .padding(.leading, 16)
                }
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .lineLimit(1...3)
                .padding(.leading, 16)
                .padding(.trailing, 44)
                .padding(.vertical, 14)
            
            // Mic icon inside text field, right side, 12pt from edge
            micButton
                .padding(.trailing, 12)
                .padding(.vertical, 14)
        }
        .frame(minHeight: 56)
        .background(
            ZStack {
                AIInputTheme.inputBg
                // Slight blur feel
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.3))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 6)
        .shadow(color: AIInputTheme.purple.opacity(0.15), radius: 12)
    }
    
    // MARK: - Mic Button
    
    private var micButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(AIInputTheme.spring) {
                isMicPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(AIInputTheme.spring) {
                    isMicPressed = false
                }
                onMicTap?()
            }
        } label: {
            ZStack {
                // Pulsing ring when listening
                if isListening {
                    Circle()
                        .stroke(AIInputTheme.purple.opacity(0.6), lineWidth: 2)
                        .scaleEffect(1 + micPulsePhase * 0.3)
                        .opacity(1 - micPulsePhase)
                }
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        isListening
                            ? AIInputTheme.purple
                            : (isMicPressed ? AIInputTheme.purple.opacity(AIInputTheme.micGlowOpacity) : .white.opacity(AIInputTheme.micDefaultOpacity))
                    )
            }
            .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .scaleEffect(isMicPressed ? 1.1 : 1)
    }
    
    private func startMicPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
            micPulsePhase = 1
        }
    }
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button {
            guard canSend else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(AIInputTheme.spring) {
                isSendPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(AIInputTheme.spring) {
                    isSendPressed = false
                }
                onSend()
            }
        } label: {
            ZStack {
                if showLoadingSpinner {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 50, height: 50)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [AIInputTheme.purple, AIInputTheme.blue],
                        startPoint: UnitPoint(x: 0.5 + 0.5 * cos(loadingRotation), y: 0.5 + 0.5 * sin(loadingRotation)),
                        endPoint: UnitPoint(x: 0.5 - 0.5 * cos(loadingRotation), y: 0.5 - 0.5 * sin(loadingRotation))
                    )
                }
            )
            .clipShape(Circle())
        }
        .onChange(of: isLoading) { _, loading in
            if loading {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    loadingRotation = .pi * 2
                }
            } else {
                loadingRotation = 0
            }
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .opacity((canSend || showLoadingSpinner) ? 1 : 0.4)
        .shadow(
            color: (canSend || showLoadingSpinner) ? AIInputTheme.purple.opacity(0.5) : .clear,
            radius: 12
        )
        .scaleEffect(isSendPressed ? 0.92 : 1)
    }
}

// MARK: - Placeholder Extension

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var focused: Bool
        
        var body: some View {
            ZStack {
                Color(hex: "0B1220").ignoresSafeArea()
                VStack {
                    Spacer()
                    AIInputBar(text: $text, isFocused: $focused, onSend: {})
                        .padding()
                }
            }
        }
    }
    return PreviewWrapper()
}
