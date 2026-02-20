import SwiftUI

struct NotificationsView: View {
    let notifications: [GitHubNotification]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Notifications", icon: "bell.fill")
            if isLoading && notifications.isEmpty {
                loadingRow()
            } else if notifications.isEmpty {
                emptyRow("No unread notifications")
            } else {
                ForEach(notifications) { notif in
                    notifRow(notif)
                    if notif.id != notifications.last?.id {
                        Divider().opacity(0.15)
                    }
                }
            }
        }
    }

    private func notifRow(_ notif: GitHubNotification) -> some View {
        Button {
            if let url = URL(string: notif.repository.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: notif.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(notif.unread ? Theme.accent : Theme.dimmed)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(notif.subject.title)
                        .font(Theme.monoSmall)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        Text(notif.shortRepo)
                        Text("~")
                        Text(notif.reason)
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.dimmed)
                }
                Spacer()
            }
            .padding(.horizontal, Theme.padding)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.monoTitle)
                .foregroundStyle(.white)
            Spacer()
            let unread = notifications.filter(\.unread).count
            if unread > 0 {
                Text("\(unread)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accent, in: Capsule())
            }
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 8)
    }

    private func loadingRow() -> some View {
        HStack {
            ProgressView().controlSize(.small)
            Text("Loading...").font(Theme.monoSmall).foregroundStyle(Theme.dimmed)
        }
        .padding(Theme.padding)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(Theme.monoSmall)
            .foregroundStyle(Theme.dimmed)
            .padding(Theme.padding)
    }
}
