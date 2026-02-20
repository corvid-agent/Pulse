import Foundation

// MARK: - Inline Model Copies (for standalone test binary)

struct GitHubEvent: Codable, Identifiable {
    let id: String
    let type: String
    let repo: Repo
    let createdAt: String
    let payload: Payload?

    enum CodingKeys: String, CodingKey {
        case id, type, repo, payload
        case createdAt = "created_at"
    }

    struct Repo: Codable { let name: String }

    struct Payload: Codable {
        let action: String?
        let ref: String?
        let refType: String?
        let size: Int?
        let pullRequest: PayloadPR?

        enum CodingKeys: String, CodingKey {
            case action, ref, size
            case refType = "ref_type"
            case pullRequest = "pull_request"
        }
    }

    struct PayloadPR: Codable { let title: String? }

    var icon: String {
        switch type {
        case "PushEvent": return "arrow.up.circle.fill"
        case "PullRequestEvent": return "arrow.triangle.merge"
        case "IssuesEvent": return "exclamationmark.circle.fill"
        case "WatchEvent": return "star.fill"
        case "CreateEvent": return "plus.circle.fill"
        case "DeleteEvent": return "minus.circle.fill"
        case "ForkEvent": return "tuningfork"
        case "IssueCommentEvent": return "text.bubble.fill"
        case "PullRequestReviewEvent": return "eye.fill"
        default: return "circle.fill"
        }
    }

    var summary: String {
        let repo = repo.name.split(separator: "/").last.map(String.init) ?? repo.name
        switch type {
        case "PushEvent":
            let n = payload?.size ?? 0
            return "Pushed \(n) commit\(n == 1 ? "" : "s") to \(repo)"
        case "PullRequestEvent":
            let action = payload?.action ?? "updated"
            let title = payload?.pullRequest?.title ?? "PR"
            return "\(action.capitalized) PR: \(title)"
        case "IssuesEvent":
            return "\(payload?.action?.capitalized ?? "Updated") issue in \(repo)"
        case "WatchEvent":
            return "Starred \(repo)"
        case "CreateEvent":
            let ref = payload?.refType ?? "repo"
            return "Created \(ref) in \(repo)"
        case "ForkEvent":
            return "Forked \(repo)"
        case "IssueCommentEvent":
            return "Commented in \(repo)"
        case "PullRequestReviewEvent":
            return "Reviewed PR in \(repo)"
        default:
            return "\(type.replacingOccurrences(of: "Event", with: "")) in \(repo)"
        }
    }
}

struct GitHubNotification: Codable, Identifiable {
    let id: String
    let unread: Bool
    let reason: String
    let subject: Subject
    let repository: NotifRepo
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, unread, reason, subject, repository
        case updatedAt = "updated_at"
    }

    struct Subject: Codable {
        let title: String
        let type: String
    }

    struct NotifRepo: Codable {
        let fullName: String
        let htmlUrl: String
        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case htmlUrl = "html_url"
        }
    }

    var icon: String {
        switch subject.type {
        case "PullRequest": return "arrow.triangle.merge"
        case "Issue": return "exclamationmark.circle.fill"
        case "Release": return "tag.fill"
        case "Discussion": return "bubble.left.and.bubble.right.fill"
        default: return "bell.fill"
        }
    }

    var shortRepo: String {
        repository.fullName.split(separator: "/").last.map(String.init) ?? repository.fullName
    }
}

struct SearchResults: Codable {
    let totalCount: Int
    let items: [PullRequest]
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

struct PullRequest: Codable, Identifiable {
    let id: Int
    let title: String
    let htmlUrl: String
    let state: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, state
        case htmlUrl = "html_url"
        case createdAt = "created_at"
    }

    var repoName: String {
        let parts = htmlUrl.split(separator: "/")
        if parts.count >= 5 { return String(parts[parts.count - 3]) }
        return ""
    }

    init(id: Int, title: String, htmlUrl: String, state: String, createdAt: String) {
        self.id = id; self.title = title; self.htmlUrl = htmlUrl
        self.state = state; self.createdAt = createdAt
    }
}

// URL construction helpers (mirroring GitHubService)
enum ServiceURLs {
    static let base = "https://api.github.com"
    static func eventsURL(for user: String) -> String { "\(base)/users/\(user)/events?per_page=10" }
    static func notificationsURL() -> String { "\(base)/notifications?per_page=20" }
    static func openPRsURL(for user: String) -> String {
        "\(base)/search/issues?q=author:\(user)+type:pr+state:open&per_page=10"
    }
}

// Theme constants (mirroring Theme.swift)
enum ThemeTest {
    static let windowWidth: CGFloat = 380
    static let windowHeight: CGFloat = 520
    static let cornerRadius: CGFloat = 8
    static let padding: CGFloat = 10
}

// MARK: - Test Harness

var passes = 0
var failures = 0

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "", file: String = #file, line: Int = #line) {
    if a == b {
        passes += 1
    } else {
        failures += 1
        print("  FAIL [\(file.split(separator: "/").last ?? ""):\(line)] \(msg)")
        print("    expected: \(b)")
        print("    got:      \(a)")
    }
}

func assertTrue(_ value: Bool, _ msg: String = "", file: String = #file, line: Int = #line) {
    assertEqual(value, true, msg, file: file, line: line)
}

func section(_ name: String) { print("\n--- \(name) ---") }

// MARK: - Tests

func testEventParsing() {
    section("GitHubEvent parsing")
    let json = """
    [{"id":"123","type":"PushEvent","repo":{"name":"user/my-repo"},"created_at":"2025-01-15T10:30:00Z","payload":{"size":3,"ref":"refs/heads/main"}}]
    """.data(using: .utf8)!
    do {
        let events = try JSONDecoder().decode([GitHubEvent].self, from: json)
        assertEqual(events.count, 1, "Should parse 1 event")
        assertEqual(events[0].id, "123", "Event ID")
        assertEqual(events[0].type, "PushEvent", "Event type")
        assertEqual(events[0].repo.name, "user/my-repo", "Repo name")
        assertEqual(events[0].icon, "arrow.up.circle.fill", "Push icon")
        assertEqual(events[0].summary, "Pushed 3 commits to my-repo", "Push summary")
    } catch {
        failures += 1
        print("  FAIL: Event parsing threw: \(error)")
    }
}

func testEventIcons() {
    section("Event icon mapping")
    let types: [(String, String)] = [
        ("PushEvent", "arrow.up.circle.fill"),
        ("PullRequestEvent", "arrow.triangle.merge"),
        ("IssuesEvent", "exclamationmark.circle.fill"),
        ("WatchEvent", "star.fill"),
        ("CreateEvent", "plus.circle.fill"),
        ("ForkEvent", "tuningfork"),
        ("UnknownEvent", "circle.fill"),
    ]
    for (type, expected) in types {
        let json = """
        [{"id":"1","type":"\(type)","repo":{"name":"a/b"},"created_at":"2025-01-01T00:00:00Z","payload":null}]
        """.data(using: .utf8)!
        if let events = try? JSONDecoder().decode([GitHubEvent].self, from: json) {
            assertEqual(events[0].icon, expected, "\(type) icon")
        } else {
            failures += 1
            print("  FAIL: Could not decode \(type)")
        }
    }
}

func testNotificationParsing() {
    section("GitHubNotification parsing")
    let json = """
    [{"id":"456","unread":true,"reason":"mention","subject":{"title":"Fix bug","type":"PullRequest"},"repository":{"full_name":"org/repo","html_url":"https://github.com/org/repo"},"updated_at":"2025-01-15T12:00:00Z"}]
    """.data(using: .utf8)!
    do {
        let notifs = try JSONDecoder().decode([GitHubNotification].self, from: json)
        assertEqual(notifs.count, 1, "Should parse 1 notification")
        assertEqual(notifs[0].id, "456", "Notif ID")
        assertTrue(notifs[0].unread, "Should be unread")
        assertEqual(notifs[0].reason, "mention", "Reason")
        assertEqual(notifs[0].subject.title, "Fix bug", "Subject title")
        assertEqual(notifs[0].subject.type, "PullRequest", "Subject type")
        assertEqual(notifs[0].icon, "arrow.triangle.merge", "PR notification icon")
        assertEqual(notifs[0].shortRepo, "repo", "Short repo name")
    } catch {
        failures += 1
        print("  FAIL: Notification parsing threw: \(error)")
    }
}

func testNotificationIcons() {
    section("Notification icon mapping")
    let make: (String) -> String? = { type in
        let json = """
        [{"id":"1","unread":false,"reason":"assign","subject":{"title":"t","type":"\(type)"},"repository":{"full_name":"a/b","html_url":"https://github.com/a/b"},"updated_at":"2025-01-01T00:00:00Z"}]
        """.data(using: .utf8)!
        return try? JSONDecoder().decode([GitHubNotification].self, from: json).first?.icon
    }
    assertEqual(make("PullRequest"), "arrow.triangle.merge", "PR icon")
    assertEqual(make("Issue"), "exclamationmark.circle.fill", "Issue icon")
    assertEqual(make("Release"), "tag.fill", "Release icon")
    assertEqual(make("Other"), "bell.fill", "Default icon")
}

func testSearchResultsParsing() {
    section("SearchResults / PullRequest parsing")
    let json = """
    {"total_count":2,"items":[{"id":100,"title":"Add feature X","html_url":"https://github.com/org/repo/pull/42","state":"open","created_at":"2025-01-10T08:00:00Z"},{"id":101,"title":"Fix typo","html_url":"https://github.com/org/other/pull/7","state":"open","created_at":"2025-01-11T09:00:00Z"}]}
    """.data(using: .utf8)!
    do {
        let results = try JSONDecoder().decode(SearchResults.self, from: json)
        assertEqual(results.totalCount, 2, "Total count")
        assertEqual(results.items.count, 2, "Item count")
        assertEqual(results.items[0].title, "Add feature X", "PR title")
        assertEqual(results.items[0].repoName, "repo", "Repo from URL")
        assertEqual(results.items[1].repoName, "other", "Second repo name")
    } catch {
        failures += 1
        print("  FAIL: SearchResults parsing threw: \(error)")
    }
}

func testURLConstruction() {
    section("GitHubService URL construction")
    assertEqual(ServiceURLs.eventsURL(for: "octocat"),
                "https://api.github.com/users/octocat/events?per_page=10", "Events URL")
    assertEqual(ServiceURLs.notificationsURL(),
                "https://api.github.com/notifications?per_page=20", "Notifications URL")
    assertEqual(ServiceURLs.openPRsURL(for: "octocat"),
                "https://api.github.com/search/issues?q=author:octocat+type:pr+state:open&per_page=10", "Open PRs URL")
}

func testThemeValues() {
    section("Theme constants")
    assertEqual(ThemeTest.windowWidth, 380, "Window width")
    assertEqual(ThemeTest.windowHeight, 520, "Window height")
    assertEqual(ThemeTest.cornerRadius, 8, "Corner radius")
    assertEqual(ThemeTest.padding, 10, "Padding")
}

func testEventSummaryCases() {
    section("Event summary edge cases")
    let single = """
    [{"id":"1","type":"PushEvent","repo":{"name":"u/r"},"created_at":"2025-01-01T00:00:00Z","payload":{"size":1}}]
    """.data(using: .utf8)!
    if let ev = try? JSONDecoder().decode([GitHubEvent].self, from: single) {
        assertEqual(ev[0].summary, "Pushed 1 commit to r", "Singular commit")
    }

    let watch = """
    [{"id":"2","type":"WatchEvent","repo":{"name":"cool/project"},"created_at":"2025-01-01T00:00:00Z","payload":{"action":"started"}}]
    """.data(using: .utf8)!
    if let ev = try? JSONDecoder().decode([GitHubEvent].self, from: watch) {
        assertEqual(ev[0].summary, "Starred project", "Star summary")
    }

    let create = """
    [{"id":"3","type":"CreateEvent","repo":{"name":"a/b"},"created_at":"2025-01-01T00:00:00Z","payload":{"ref_type":"branch"}}]
    """.data(using: .utf8)!
    if let ev = try? JSONDecoder().decode([GitHubEvent].self, from: create) {
        assertEqual(ev[0].summary, "Created branch in b", "Create summary")
    }
}

func testPullRequestInit() {
    section("PullRequest manual init")
    let pr = PullRequest(id: 1, title: "Test", htmlUrl: "https://github.com/a/myrepo/pull/5", state: "open", createdAt: "2025-01-01")
    assertEqual(pr.repoName, "myrepo", "Manual init repo name")
    assertEqual(pr.title, "Test", "Manual init title")
}

// MARK: - Runner

@main
struct TestRunner {
    static func main() {
        print("Pulse Test Suite")
        print("================")

        testEventParsing()
        testEventIcons()
        testNotificationParsing()
        testNotificationIcons()
        testSearchResultsParsing()
        testURLConstruction()
        testThemeValues()
        testEventSummaryCases()
        testPullRequestInit()

        print("\n================")
        print("Results: \(passes) passed, \(failures) failed")
        if failures > 0 {
            print("SOME TESTS FAILED")
            exit(1)
        } else {
            print("ALL TESTS PASSED")
        }
    }
}
