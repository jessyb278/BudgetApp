import SwiftUI

struct InsightsScreen: View {
    @StateObject private var data = SupabaseDataService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                ForEach(data.insights) { insight in
                    InsightCard(insight: insight)
                }
            }
            .padding()
        }
        .background(AppTheme.backgroundPrimary)
        .navigationTitle("Plan")
        .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
    }
}
