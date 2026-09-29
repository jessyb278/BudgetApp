import Foundation
import Combine

/// Handles Plaid Link flow: fetch link_token → open Link → exchange public_token
@MainActor
final class PlaidService: ObservableObject {
    static let shared = PlaidService()

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastLinkSuccess: (accounts: Int, transactions: Int)?

    private let supabaseUrl = SupabaseConfig.url
    private var session: URLSession { URLSession.shared }

    private init() {}

    /// Fetches a link_token from our Supabase Edge Function (requires auth)
    func fetchLinkToken(authToken: String) async throws -> String {
        let url = supabaseUrl.appendingPathComponent("functions/v1/plaid-create-link-token")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, res) = try await session.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw PlaidError.network }
        guard http.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? String {
                throw PlaidError.server(err)
            }
            throw PlaidError.server("Failed to get link token (\(http.statusCode))")
        }

        struct Response: Decodable { let link_token: String }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.link_token
    }

    /// Sends public_token to our Edge Function to exchange and sync data
    func exchangeToken(publicToken: String, authToken: String) async throws -> (accounts: Int, transactions: Int) {
        let url = supabaseUrl.appendingPathComponent("functions/v1/plaid-exchange")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["public_token": publicToken])

        let (data, res) = try await session.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw PlaidError.network }

        struct Response: Decodable {
            let success: Bool?
            let accounts_count: Int?
            let transactions_count: Int?
            let error: String?
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)

        if let err = decoded.error {
            throw PlaidError.server(err)
        }
        guard http.statusCode == 200, decoded.success == true else {
            throw PlaidError.server("Exchange failed (\(http.statusCode))")
        }

        let accts = decoded.accounts_count ?? 0
        let txns = decoded.transactions_count ?? 0
        return (accts, txns)
    }

    /// Refreshes accounts and transactions for all linked institutions
    func refreshAccounts(authToken: String) async throws -> (accountsUpdated: Int, transactionsAdded: Int) {
        let url = supabaseUrl.appendingPathComponent("functions/v1/plaid-sync")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode([String: String]())

        let (data, res) = try await session.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw PlaidError.network }
        guard http.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? String {
                throw PlaidError.server(err)
            }
            throw PlaidError.server("Refresh failed (\(http.statusCode))")
        }

        struct Response: Decodable {
            let success: Bool?
            let accounts_updated: Int?
            let transactions_added: Int?
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return (decoded.accounts_updated ?? 0, decoded.transactions_added ?? 0)
    }

    /// Disconnects all linked institutions (removes connections, accounts, transactions)
    func disconnectAllInstitutions(authToken: String) async throws {
        let url = supabaseUrl.appendingPathComponent("functions/v1/plaid-disconnect")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = "{}".data(using: .utf8)

        let (data, res) = try await session.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw PlaidError.network }
        guard http.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? String {
                throw PlaidError.server(err)
            }
            throw PlaidError.server("Failed to disconnect (\(http.statusCode))")
        }
    }
}

enum PlaidError: LocalizedError {
    case network
    case server(String)

    var errorDescription: String? {
        switch self {
        case .network: return "Network error"
        case .server(let msg): return msg
        }
    }
}
