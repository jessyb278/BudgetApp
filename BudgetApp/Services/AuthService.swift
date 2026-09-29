import Foundation
import Combine
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var session: Session?
    @Published var isAuthenticated = false
    @Published var authError: String?

    var userIdentifier: String? {
        session?.user.email ?? session?.user.phone
    }

    private let client = SupabaseService.shared.client

    private init() {
        session = client.auth.currentSession
        isAuthenticated = session != nil
        Task { await listenForAuthChanges() }
    }

    func signUp(email: String, password: String) async throws {
        authError = nil
        _ = try await client.auth.signUp(email: email, password: password)
        session = try? await client.auth.session
        isAuthenticated = session != nil
    }

    func signIn(email: String, password: String) async throws {
        authError = nil
        _ = try await client.auth.signIn(email: email, password: password)
        session = try await client.auth.session
        isAuthenticated = true
    }

    func signOut() async throws {
        authError = nil
        try await client.auth.signOut()
        session = nil
        isAuthenticated = false
    }

    func restoreSession() async {
        do {
            let s = try await client.auth.session
            session = s
            isAuthenticated = true
        } catch {
            session = nil
            isAuthenticated = false
        }
    }

    private func listenForAuthChanges() async {
        for await (event, _) in client.auth.authStateChanges {
            switch event {
            case .signedIn, .tokenRefreshed:
                session = try? await client.auth.session
                isAuthenticated = session != nil
            case .signedOut, .userUpdated:
                session = try? await client.auth.session
                isAuthenticated = session != nil
            default:
                break
            }
        }
    }
}
