import SwiftUI

@main
struct PulseApp: App {
    @StateObject private var badgeModel = BadgeModel()

    var body: some Scene {
        MenuBarExtra {
            PulseView()
                .environmentObject(badgeModel)
        } label: {
            Label {
                Text("Pulse")
            } icon: {
                Image(systemName: badgeModel.unreadCount > 0 ? "heart.circle.fill" : "heart.fill")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class BadgeModel: ObservableObject {
    @Published var unreadCount: Int = 0
}
