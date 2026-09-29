import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthService.shared
    @State private var showSignUp = false

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainView()
            } else if showSignUp {
                SignUpView(showSignUp: $showSignUp)
            } else {
                LoginView(showSignUp: $showSignUp)
            }
        }
        .task {
            await auth.restoreSession()
        }
    }
}
