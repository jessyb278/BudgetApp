import SwiftUI

struct MainView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var data = SupabaseDataService.shared
    @State private var selectedTab = 0
    @State private var showAIFullScreen = false
    @State private var previousTabBeforeAI = 0
    
    private let tabs = [
        TabItem(id: 0, icon: "house.fill", label: "Home"),
        TabItem(id: 1, icon: "list.bullet", label: "Activity"),
        TabItem(id: 2, icon: "sparkles", label: "AI"),
        TabItem(id: 3, icon: "chart.line.uptrend.xyaxis", label: "Plan"),
        TabItem(id: 4, icon: "ellipsis.circle.fill", label: "More"),
    ]
    
    private var displayedTab: Int {
        selectedTab == 2 ? previousTabBeforeAI : selectedTab
    }
    
    var body: some View {
        CustomTabView(selectedTab: $selectedTab, displayedTab: displayedTab, tabs: tabs) { tab in
            switch tab {
            case 0: DashboardView()
            case 1: TransactionsScreen()
            case 2: DashboardView()
            case 3: PlanScreen()
            case 4: MoreView()
            default: DashboardView()
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                previousTabBeforeAI = oldValue == 2 ? 0 : oldValue
                showAIFullScreen = true
            }
        }
        .fullScreenCover(isPresented: $showAIFullScreen) {
            AIAssistantView(onDismiss: {
                showAIFullScreen = false
                selectedTab = previousTabBeforeAI
            })
        }
        .task {
            await data.fetchAll()
        }
        .onAppear {
            Task { await data.fetchAll() }
        }
        .onChange(of: auth.isAuthenticated) { _, isAuth in
            if isAuth { Task { await data.fetchAll() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await data.fetchAll() }
        }
    }
}
