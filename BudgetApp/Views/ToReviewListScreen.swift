import SwiftUI

struct ToReviewListScreen: View {
    @Environment(\.theme) private var theme
    @StateObject private var data = SupabaseDataService.shared
    let transactions: [Transaction]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingM) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, tx in
                    NavigationLink(value: HomeRoute.transaction(tx.id)) {
                        ReviewItem(
                            transaction: tx,
                            index: index,
                            onTap: nil,
                            onReview: { Task { await data.markReviewed(tx) } }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.spacingXXL)
            .padding(.bottom, AppTheme.tabBarHeight + AppTheme.spacingXL)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("To Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundPrimary, for: .navigationBar)
    }
}
