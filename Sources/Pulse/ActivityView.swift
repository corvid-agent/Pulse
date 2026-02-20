import SwiftUI

struct ActivityView: View {
    let events: [GitHubEvent]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Recent Activity", icon: "bolt.fill")
            if isLoading && events.isEmpty {
                loadingRow()
            } else if events.isEmpty {
                emptyRow("No recent activity")
            } else {
                ForEach(events) { event in
                    eventRow(event)
                    if event.id != events.last?.id {
                        Divider().opacity(0.15)
                    }
                }
            }
        }
    }

    private func eventRow(_ event: GitHubEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: event.icon)
                .font(.system(size: 11))
                .foregroundStyle(Theme.accent)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.summary)
                    .font(Theme.monoSmall)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(event.relativeTime)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.dimmed)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
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
            Text("\(events.count)")
                .font(Theme.monoSmall)
                .foregroundStyle(Theme.dimmed)
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
