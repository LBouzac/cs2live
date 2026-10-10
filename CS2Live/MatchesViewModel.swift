import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var live: [Match] = []
    @Published var upcoming: [Match] = []
    @Published var recent: [Match] = []
    @Published var errorMessage: String?
    @Published var lastUpdate: Date?
    @Published var onlyTwitch = true

    // Équipe favorite, persistée dans UserDefaults.
    @Published var favoriteTeamID: Int = UserDefaults.standard.integer(forKey: "favoriteTeamID") {
        didSet { UserDefaults.standard.set(favoriteTeamID, forKey: "favoriteTeamID") }
    }
    @Published var favoriteTeamName: String = UserDefaults.standard.string(forKey: "favoriteTeamName") ?? "" {
        didSet { UserDefaults.standard.set(favoriteTeamName, forKey: "favoriteTeamName") }
    }
    @Published var favoriteTeamLogo: String = UserDefaults.standard.string(forKey: "favoriteTeamLogo") ?? "" {
        didSet { UserDefaults.standard.set(favoriteTeamLogo, forKey: "favoriteTeamLogo") }
    }

    private var pollTask: Task<Void, Never>?
    private var notifiedLiveIDs = Set<Int>()
    private var lastScores: [Int: String] = [:]

    var hasFavorite: Bool { favoriteTeamID != 0 }

    var favoriteLive: [Match] {
        live.filter { $0.involves(teamID: favoriteTeamID) }
    }

    var otherLive: [Match] {
        live.filter { !$0.involves(teamID: favoriteTeamID) && (!onlyTwitch || $0.isOnTwitch) }
    }

    func setFavorite(_ team: Team) {
        favoriteTeamID = team.id
        favoriteTeamName = team.name
        favoriteTeamLogo = team.imageURL?.absoluteString ?? ""
        notifiedLiveIDs.removeAll()
        Task { await refresh() }
    }

    // MARK: - Rafraîchissement en temps réel (polling)

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(Config.refreshInterval))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() async {
        do {
            async let liveReq = PandaScoreService.shared.runningMatches()
            async let upReq = PandaScoreService.shared.upcomingMatches(teamID: hasFavorite ? favoriteTeamID : nil)
            let (l, u) = try await (liveReq, upReq)

            live = l.sorted { ($0.isOnTwitch ? 0 : 1) < ($1.isOnTwitch ? 0 : 1) }
            upcoming = u
            if hasFavorite {
                recent = (try? await PandaScoreService.shared.pastMatches(teamID: favoriteTeamID)) ?? recent
            }
            errorMessage = nil
            lastUpdate = .now
            notifyFavoriteChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Notifications locales

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func notifyFavoriteChanges() {
        guard hasFavorite else { return }
        for match in favoriteLive {
            let scoreKey = "\(match.score(for: match.teamA))-\(match.score(for: match.teamB))"

            if !notifiedLiveIDs.contains(match.id) {
                notifiedLiveIDs.insert(match.id)
                lastScores[match.id] = scoreKey
                send(title: "🔴 \(favoriteTeamName) est en live !",
                     body: "\(match.name)\(match.isOnTwitch ? " — sur Twitch" : "")")
            } else if lastScores[match.id] != scoreKey {
                lastScores[match.id] = scoreKey
                send(title: "Map terminée : \(match.teamA?.acronym ?? match.teamA?.name ?? "") \(scoreKey) \(match.teamB?.acronym ?? match.teamB?.name ?? "")",
                     body: match.name)
            }
        }
    }

    private func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
