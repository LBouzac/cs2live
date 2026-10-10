import SwiftUI
import UserNotifications

@main
struct CS2LiveApp: App {
    @StateObject private var vm = MatchesViewModel()
    @Environment(\.scenePhase) private var scenePhase
    private let notifDelegate = ForegroundNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notifDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .onAppear { vm.requestNotificationPermission() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { vm.startPolling() } else { vm.stopPolling() }
        }
    }
}

/// Affiche les notifications même quand l'app est ouverte.
final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

enum Theme {
    static let accent = Color(red: 0.98, green: 0.62, blue: 0.12)   // orange CS
    static let twitch = Color(red: 0.57, green: 0.27, blue: 1.0)    // violet Twitch
    static let live = Color.red
    static let card = Color(white: 0.12)
}
