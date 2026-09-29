import SwiftUI

struct MoreView: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared
    @StateObject private var auth = AuthService.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("biometricEnabled") private var biometricEnabled = true
    @AppStorage("aiInsightsEnabled") private var aiInsightsEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingXL) {
                    profileSection
                    connectedAccountsSection
                    securitySection
                    notificationsSection
                    preferencesSection
                    aiSettingsSection
                    dataExportSection
                    helpSupportSection
                    legalSection
                    dangerZoneSection
                }
                .padding(AppTheme.spacingXXL)
                .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
            }
            .ignoresSafeArea(edges: .bottom)
            .background(theme.backgroundPrimary)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
        }
    }

    private var profileSection: some View {
        MoreSectionCard(title: "Profile") {
            NavigationLink {
                SettingsInfoScreen(title: "Personal Info", lines: [
                    "Email: \(auth.userIdentifier ?? "—")",
                    "Linked accounts: \(data.accounts.count)",
                ])
            } label: {
                MoreNavRow(icon: "person.circle.fill", title: "Personal Info", subtitle: auth.userIdentifier ?? "\(data.accounts.count) accounts linked")
            }
            .buttonStyle(.plain)

            Button {
                Task { try? await auth.signOut() }
            } label: {
                MoreNavRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", isDestructive: false)
            }
            .buttonStyle(.plain)

            NavigationLink {
                SettingsInfoScreen(title: "Subscription", lines: [
                    "Current plan: Pro",
                    "Benefits: Unlimited insights, advanced planning",
                    "Billing date: Apr 3",
                    "Manage plan options are mocked."
                ])
            } label: {
                MoreNavRow(icon: "creditcard.fill", title: "Subscription / Plan", subtitle: "Pro Plan")
            }
            .buttonStyle(.plain)

        }
    }

    private var connectedAccountsSection: some View {
        MoreSectionCard(title: "Connected Accounts") {
            NavigationLink {
                ConnectedAccountsScreen()
            } label: {
                MoreNavRow(icon: "building.2.fill", title: "Manage Accounts", subtitle: lastSyncText)
            }
            .buttonStyle(.plain)
            NavigationLink {
                ConnectBankView()
            } label: {
                MoreNavRow(icon: "link", title: "Connect Bank", subtitle: "Link your bank with Plaid")
            }
            .buttonStyle(.plain)
        }
    }

    private var securitySection: some View {
        MoreSectionCard(title: "Security") {
            MoreToggleRow(icon: "lock.fill", title: "Face ID / Touch ID", isOn: $biometricEnabled)
            NavigationLink {
                SettingsInfoScreen(title: "Change Password", lines: [
                    "Current password",
                    "New password",
                    "Confirm password",
                    "Save button (mock)"
                ])
            } label: {
                MoreNavRow(icon: "key.fill", title: "Change Password")
            }
            .buttonStyle(.plain)

            NavigationLink {
                SettingsInfoScreen(title: "Two-Factor Authentication", lines: [
                    "Current status: Enabled",
                    "Methods: SMS, Authenticator App",
                    "Enable/disable CTA",
                    "Device verification steps (mock)"
                ])
            } label: {
                MoreNavRow(icon: "shield.fill", title: "Two-Factor Auth")
            }
            .buttonStyle(.plain)
        }
    }

    private var notificationsSection: some View {
        MoreSectionCard(title: "Notifications") {
            MoreToggleRow(icon: "bell.fill", title: "Push Notifications", isOn: $notificationsEnabled)
            navInfoRow(icon: "chart.line.uptrend.xyaxis", title: "Spending Alerts", lines: [
                "Overspending alert toggle",
                "Unusual transaction alert toggle",
                "Category thresholds",
                "Quiet hours"
            ])
            navInfoRow(icon: "calendar", title: "Bill Reminders", lines: [
                "Reminder timing",
                "Reminder methods",
                "Recurring bill reminder list"
            ])
            navInfoRow(icon: "flag.fill", title: "Goal Milestones", lines: [
                "Milestone alerts toggle",
                "Threshold examples",
                "Enabled goals"
            ])
            navInfoRow(icon: "calendar.badge.clock", title: "Weekly Summary", lines: [
                "Email summary toggle",
                "Push summary toggle",
                "Preferred day and time"
            ])
        }
    }

    private var preferencesSection: some View {
        MoreSectionCard(title: "Preferences") {
            navInfoRow(icon: "dollarsign", title: "Currency", subtitle: "USD", lines: ["USD", "EUR", "GBP", "JPY", "CAD"])
            NavigationLink {
                AppearancePickerScreen()
            } label: {
                MoreNavRow(icon: "moon.fill", title: "Appearance")
            }
            .buttonStyle(.plain)
            navInfoRow(icon: "globe", title: "Language", lines: ["English (US)", "Spanish", "French", "German"])
            navInfoRow(icon: "number", title: "Date / Number Format", lines: [
                "Number format: 1,234.56",
                "Date format: MMM d, yyyy",
                "Decimal separator examples"
            ])
        }
    }

    private var aiSettingsSection: some View {
        MoreSectionCard(title: "AI Settings") {
            MoreToggleRow(icon: "sparkles", title: "AI Insights", isOn: $aiInsightsEnabled)
            navInfoRow(icon: "text.bubble.fill", title: "AI Assistant Preferences", lines: [
                "Preferred tone",
                "Focus area: saving, budgeting, subscriptions, debt",
                "Summary style",
                "Response length"
            ])
            navInfoRow(icon: "person.crop.circle.badge.checkmark", title: "Personalization", lines: [
                "Memory toggle",
                "Personalized suggestions toggle",
                "Learn from categories toggle"
            ])
            navInfoRow(icon: "shield.checkerboard", title: "Data used by AI", lines: [
                "What data is used",
                "What is not used",
                "Privacy explanation",
                "Control toggles"
            ])
        }
    }

    private var dataExportSection: some View {
        MoreSectionCard(title: "Data & Export") {
            navInfoRow(icon: "square.and.arrow.up.fill", title: "Export Data", lines: [
                "Export type",
                "File format",
                "Date range",
                "Export button"
            ])
            navInfoRow(icon: "arrow.down.doc.fill", title: "Download Transactions", lines: [
                "CSV / JSON options",
                "Account filters",
                "Date filters",
                "Download button"
            ])
        }
    }

    private var helpSupportSection: some View {
        MoreSectionCard(title: "Help & Support") {
            navInfoRow(icon: "questionmark.circle.fill", title: "Help Center", lines: ["FAQ", "Getting started", "Billing help", "Security help"])
            navInfoRow(icon: "envelope.fill", title: "Contact Us", lines: ["support@budgetapp.mock", "Contact form mock", "Response within 24 hours"])
            navInfoRow(icon: "star.fill", title: "Rate the App", lines: ["Mock rating prompt and app store placeholder"])
            navInfoRow(icon: "ladybug.fill", title: "Report a Bug", lines: ["Issue summary", "Steps to reproduce", "Attachment placeholder"])
        }
    }

    private var legalSection: some View {
        MoreSectionCard(title: "Legal") {
            navInfoRow(icon: "doc.text.fill", title: "Privacy Policy", lines: Array(repeating: "Mock privacy policy content for frontend prototype.", count: 7))
            navInfoRow(icon: "doc.plaintext.fill", title: "Terms of Service", lines: Array(repeating: "Mock terms content for frontend prototype.", count: 7))
            navInfoRow(icon: "checkmark.shield.fill", title: "Licenses", lines: [
                "SwiftUI Framework License Placeholder",
                "Charts License Placeholder",
                "Open-source acknowledgements"
            ])
        }
    }

    private var dangerZoneSection: some View {
        MoreSectionCard(title: "Danger Zone") {
            NavigationLink {
                DeleteAccountScreen()
            } label: {
                MoreNavRow(icon: "trash.fill", title: "Delete Account", isDestructive: true)
            }
            .buttonStyle(.plain)

            NavigationLink {
                ConnectedAccountsScreen()
            } label: {
                MoreNavRow(icon: "link.badge.minus", title: "Disconnect Institutions", subtitle: "Manage or remove linked accounts", isDestructive: true)
            }
            .buttonStyle(.plain)
        }
    }

    private var lastSyncText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let syncDate = Calendar.current.date(byAdding: .minute, value: -12, to: Date()) ?? Date()
        return "Synced \(formatter.localizedString(for: syncDate, relativeTo: Date()))"
    }

    private func navInfoRow(icon: String, title: String, subtitle: String? = nil, isDestructive: Bool = false, lines: [String]) -> some View {
        NavigationLink {
            SettingsInfoScreen(title: title, lines: lines)
        } label: {
            MoreNavRow(icon: icon, title: title, subtitle: subtitle, isDestructive: isDestructive)
        }
        .buttonStyle(.plain)
    }
}

struct MoreSectionCard<Content: View>: View {
    @Environment(\.theme) private var theme
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text(title)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(theme.textSecondary)
                .padding(.bottom, AppTheme.spacingM)
            content
        }
        .padding(AppTheme.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
    }
}

struct MoreNavRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    var subtitle: String? = nil
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isDestructive ? theme.accentRed : theme.accentPrimary)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isDestructive ? theme.accentRed : theme.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(theme.textSecondary.opacity(0.9))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.textTertiary)
        }
        .padding(.vertical, 10)
    }
}

struct MoreToggleRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.accentPrimary)
                .frame(width: 24, alignment: .center)
            Text(title)
                .font(AppTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.accentPrimary)
        }
        .padding(.vertical, 10)
    }
}

struct SettingsInfoScreen: View {
    @Environment(\.theme) private var theme
    let title: String
    let lines: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct AppearancePickerScreen: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Button("Light") { appState.appearanceOverride = .light }
            Button("Dark") { appState.appearanceOverride = .dark }
            Button("System") { appState.appearanceOverride = nil }
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Appearance")
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

struct DeleteAccountScreen: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            Text("Delete your account and all associated data. This action cannot be undone.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(theme.textSecondary)
                .padding(AppTheme.spacingXXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}

#Preview {
    MoreView()
        .environmentObject(AppState())
}
