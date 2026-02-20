import Foundation

actor GitHubService {
    private let baseURL = "https://api.github.com"
    private var token: String?
    private var username: String?
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    // MARK: - Auth via gh CLI

    func authenticate() async throws {
        if token != nil && username != nil { return }
        token = try await runProcess("/usr/bin/env", arguments: ["gh", "auth", "token"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let user: GitHubUser = try await request("/user")
        username = user.login
    }

    private func runProcess(_ path: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let proc = Process()
            let pipe = Pipe()
            proc.executableURL = URL(fileURLWithPath: path)
            proc.arguments = arguments
            proc.standardOutput = pipe
            proc.standardError = pipe
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard proc.terminationStatus == 0,
                      let output = String(data: data, encoding: .utf8) else {
                    continuation.resume(throwing: PulseError.authFailed)
                    return
                }
                continuation.resume(returning: output)
            } catch {
                continuation.resume(throwing: PulseError.authFailed)
            }
        }
    }

    // MARK: - API

    func fetchEvents() async throws -> [GitHubEvent] {
        try await authenticate()
        guard let user = username else { throw PulseError.noUsername }
        let events: [GitHubEvent] = try await request("/users/\(user)/events?per_page=10")
        return events
    }

    func fetchNotifications() async throws -> [GitHubNotification] {
        try await authenticate()
        let notifs: [GitHubNotification] = try await request("/notifications?per_page=20")
        return notifs
    }

    func fetchOpenPRs() async throws -> [PullRequest] {
        try await authenticate()
        guard let user = username else { throw PulseError.noUsername }
        let query = "author:\(user)+type:pr+state:open"
        let results: SearchResults = try await request("/search/issues?q=\(query)&per_page=10")
        return results.items
    }

    func unreadCount() async throws -> Int {
        let notifs = try await fetchNotifications()
        return notifs.filter(\.unread).count
    }

    // MARK: - URL Construction (visible for testing)

    nonisolated func eventsURL(for user: String) -> String {
        "\(baseURL)/users/\(user)/events?per_page=10"
    }

    nonisolated func notificationsURL() -> String {
        "\(baseURL)/notifications?per_page=20"
    }

    nonisolated func openPRsURL(for user: String) -> String {
        let query = "author:\(user)+type:pr+state:open"
        return "\(baseURL)/search/issues?q=\(query)&per_page=10"
    }

    // MARK: - Generic Request

    private func request<T: Decodable & Sendable>(_ path: String) async throws -> T {
        guard let token = token else { throw PulseError.authFailed }
        guard let url = URL(string: "\(baseURL)\(path)") else { throw PulseError.badURL }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PulseError.apiError
        }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

enum PulseError: Error, CustomStringConvertible {
    case authFailed
    case noUsername
    case badURL
    case apiError

    var description: String {
        switch self {
        case .authFailed: return "Failed to authenticate with gh CLI"
        case .noUsername: return "Could not determine GitHub username"
        case .badURL: return "Invalid URL"
        case .apiError: return "GitHub API error"
        }
    }
}
