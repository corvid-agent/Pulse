import Foundation

// MARK: - GitHub Event

struct GitHubEvent: Codable, Identifiable, Sendable {
    let id: String
    let type: String
    let repo: Repo
    let createdAt: String
    let payload: Payload?

    enum CodingKeys: String, CodingKey {
        case id, type, repo, payload
        case createdAt = "created_at"
    }

    struct Repo: Codable, Sendable {
        let name: String
    }

    struct Payload: Codable, Sendable {
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

    struct PayloadPR: Codable, Sendable {
        let title: String?
    }

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

    var relativeTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: createdAt) else { return "" }
            return Self.relative(from: date)
        }
        return Self.relative(from: date)
    }

    private static func relative(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

// MARK: - GitHub Notification

struct GitHubNotification: Codable, Identifiable, Sendable {
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

    struct Subject: Codable, Sendable {
        let title: String
        let type: String
    }

    struct NotifRepo: Codable, Sendable {
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

// MARK: - Search Results (Open PRs)

struct SearchResults: Codable, Sendable {
    let totalCount: Int
    let items: [PullRequest]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

struct PullRequest: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let htmlUrl: String
    let state: String
    let createdAt: String
    let repository: PRRepo?

    enum CodingKeys: String, CodingKey {
        case id, title, state
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case repository = "repository_url"
    }

    struct PRRepo: Codable, Sendable {
        // repository_url is a string like "https://api.github.com/repos/owner/name"
    }

    var repoName: String {
        // Extract from htmlUrl: https://github.com/owner/repo/pull/N
        let parts = htmlUrl.split(separator: "/")
        if parts.count >= 5 {
            return String(parts[parts.count - 3])
        }
        return ""
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        htmlUrl = try c.decode(String.self, forKey: .htmlUrl)
        state = try c.decode(String.self, forKey: .state)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        repository = nil
    }

    init(id: Int, title: String, htmlUrl: String, state: String, createdAt: String) {
        self.id = id
        self.title = title
        self.htmlUrl = htmlUrl
        self.state = state
        self.createdAt = createdAt
        self.repository = nil
    }
}

// MARK: - GitHub User

struct GitHubUser: Codable, Sendable {
    let login: String
}
