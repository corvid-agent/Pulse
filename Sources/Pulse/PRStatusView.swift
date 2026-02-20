import SwiftUI

struct PRStatusView: View {
    let pullRequests: [PullRequest]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Open PRs", icon: "arrow.triangle.merge")
            if isLoading && pullRequests.isEmpty {
                loadingRow()
            } else if pullRequests.isEmpty {
                emptyRow("No open pull requests")
            } else {
                ForEach(pullRequests) { pr in
                    prRow(pr)
                    if pr.id != pullRequests.last?.id {
                        Divider().opacity(0.15)
                    }
                }
            }
        }
    }

    private func prRow(_ pr: PullRequest) -> some View {
        Button {
            if let url = URL(string: pr.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pr.title)
                        .font(Theme.monoSmall)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(pr.repoName)
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
            Text("\(pullRequests.count)")
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
