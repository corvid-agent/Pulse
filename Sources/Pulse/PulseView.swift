import SwiftUI

enum Tab: String, CaseIterable {
    case activity = "Activity"
    case prs = "PRs"
    case notifications = "Notifications"

    var icon: String {
        switch self {
        case .activity: return "bolt.fill"
        case .prs: return "arrow.triangle.merge"
        case .notifications: return "bell.fill"
        }
    }
}

@MainActor
final class PulseViewModel: ObservableObject {
    @Published var events: [GitHubEvent] = []
    @Published var pullRequests: [PullRequest] = []
    @Published var notifications: [GitHubNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = GitHubService()
    private var pollTimer: Timer?

    func startPolling() {
        Task { await refresh() }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in await self.refresh() }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            async let e = service.fetchEvents()
            async let p = service.fetchOpenPRs()
            async let n = service.fetchNotifications()
            let (ev, pr, notif) = try await (e, p, n)
            events = ev
            pullRequests = pr
            notifications = notif
            unreadCount = notif.filter(\.unread).count
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct PulseView: View {
    @StateObject private var viewModel = PulseViewModel()
    @State private var selectedTab: Tab = .activity

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            Divider().opacity(0.2)
            ScrollView {
                content
            }
            footer
        }
        .frame(width: Theme.windowWidth, height: Theme.windowHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.accent)
                Text("Pulse")
                    .font(Theme.monoTitle)
                    .foregroundStyle(.white)
            }
            Spacer()
            if viewModel.isLoading {
                ProgressView().controlSize(.small)
            }
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dimmed)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 8)
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 10))
                        Text(tab.rawValue)
                            .font(Theme.monoSmall)
                        if tab == .notifications && viewModel.unreadCount > 0 {
                            Text("\(viewModel.unreadCount)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    .foregroundStyle(selectedTab == tab ? .white : Theme.dimmed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        selectedTab == tab ? Theme.surface : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.padding)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var content: some View {
        if let err = viewModel.errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.yellow)
                Text(err)
                    .font(Theme.monoSmall)
                    .foregroundStyle(Theme.dimmed)
                    .multilineTextAlignment(.center)
                Text("Ensure `gh auth login` is configured.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.dimmed)
            }
            .padding(20)
        } else {
            switch selectedTab {
            case .activity:
                ActivityView(events: viewModel.events, isLoading: viewModel.isLoading)
            case .prs:
                PRStatusView(pullRequests: viewModel.pullRequests, isLoading: viewModel.isLoading)
            case .notifications:
                NotificationsView(notifications: viewModel.notifications, isLoading: viewModel.isLoading)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            quickLink("Repos", icon: "folder.fill", url: "https://github.com")
            quickLink("PRs", icon: "arrow.triangle.merge", url: "https://github.com/pulls")
            quickLink("Issues", icon: "exclamationmark.circle", url: "https://github.com/issues")
            quickLink("Notifs", icon: "bell.fill", url: "https://github.com/notifications")
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(Theme.monoSmall)
                .foregroundStyle(Theme.dimmed)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 8)
        .background(Theme.surface)
    }

    private func quickLink(_ label: String, icon: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 9))
                Text(label).font(.system(size: 10, design: .monospaced))
            }
            .foregroundStyle(Theme.accent)
        }
        .buttonStyle(.plain)
    }
}
