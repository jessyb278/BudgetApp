import SwiftUI

// MARK: - Credit Score Bottom Sheet

struct CreditScoreBottomSheet: View {
    @Environment(\.theme) private var theme
    let score: Int
    let change: Int
    let keyFactor: String
    let suggestion: String
    let onDismiss: () -> Void
    
    private var bandColor: Color {
        switch score {
        case 0..<580: return theme.accentRed
        case 580..<670: return theme.accentOrange
        case 670..<740: return theme.accentAmber
        case 740..<800: return theme.accentGreen
        default: return theme.accentGreen
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CreditScoreDial(score: score, width: 200, isVisible: true, showsTitle: true)
                        .frame(maxWidth: .infinity)
                    
                    if change != 0 {
                        HStack {
                            Text("Change this month")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                            Text("\(change >= 0 ? "+" : "")\(change) points")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(change >= 0 ? theme.accentGreen : theme.accentRed)
                        }
                        .padding(16)
                        .background(theme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Factor")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                        Text(keyFactor)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestion")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(theme.accentAmber)
                            Text(suggestion)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.accentAmber.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20)
            }
            .background(theme.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundStyle(bandColor)
                }
            }
        }
    }
}
