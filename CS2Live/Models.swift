import Foundation

struct Team: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let acronym: String?
    let imageURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, name, acronym
        case imageURL = "image_url"
    }
}

struct Opponent: Codable, Hashable {
    let opponent: Team
}

struct MatchResult: Codable, Hashable {
    let teamID: Int?
    let score: Int

    enum CodingKeys: String, CodingKey {
        case teamID = "team_id"
        case score
    }
}

struct MatchStream: Codable, Hashable, Identifiable {
    var id: String { rawURL?.absoluteString ?? UUID().uuidString }
    let rawURL: URL?
    let embedURL: URL?
    let language: String?
    let main: Bool?
    let official: Bool?

    enum CodingKeys: String, CodingKey {
        case rawURL = "raw_url"
        case embedURL = "embed_url"
        case language, main, official
    }

    /// Nom de la chaîne si le stream est sur Twitch (ex. "eslcs").
    var twitchChannel: String? {
        guard let url = rawURL, url.host?.contains("twitch.tv") == true else { return nil }
        return url.pathComponents.dropFirst().first
    }
}

struct Game: Codable, Hashable, Identifiable {
    let id: Int
    let position: Int
    let status: String
    let winner: Winner?

    struct Winner: Codable, Hashable { let id: Int? }
}

struct NamedEntity: Codable, Hashable {
    let name: String?
    let imageURL: URL?
    let fullName: String?

    enum CodingKeys: String, CodingKey {
        case name
        case imageURL = "image_url"
        case fullName = "full_name"
    }
}

struct Match: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let status: String              // not_started | running | finished | canceled | postponed
    let beginAt: Date?
    let scheduledAt: Date?
    let numberOfGames: Int?
    let opponents: [Opponent]
    let results: [MatchResult]
    let streamsList: [MatchStream]
    let games: [Game]?
    let league: NamedEntity?
    let serie: NamedEntity?
    let tournament: NamedEntity?

    enum CodingKeys: String, CodingKey {
        case id, name, status, opponents, results, games, league, serie, tournament
        case beginAt = "begin_at"
        case scheduledAt = "scheduled_at"
        case numberOfGames = "number_of_games"
        case streamsList = "streams_list"
    }

    var isLive: Bool { status == "running" }
    var teamA: Team? { opponents.first?.opponent }
    var teamB: Team? { opponents.dropFirst().first?.opponent }

    func score(for team: Team?) -> Int {
        guard let team else { return 0 }
        return results.first { $0.teamID == team.id }?.score ?? 0
    }

    func involves(teamID: Int) -> Bool {
        opponents.contains { $0.opponent.id == teamID }
    }

    /// Streams Twitch uniquement, le principal / officiel en premier.
    var twitchStreams: [MatchStream] {
        streamsList
            .filter { $0.twitchChannel != nil }
            .sorted { ($0.main == true ? 0 : 1, $0.official == true ? 0 : 1) < ($1.main == true ? 0 : 1, $1.official == true ? 0 : 1) }
    }

    var isOnTwitch: Bool { !twitchStreams.isEmpty }

    var formatLabel: String {
        guard let n = numberOfGames else { return "" }
        return "BO\(n)"
    }

    var currentMapLabel: String? {
        guard isLive, let games else { return nil }
        if let running = games.first(where: { $0.status == "running" }) {
            return "Map \(running.position)"
        }
        return nil
    }
}
