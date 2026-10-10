import Foundation

enum APIError: LocalizedError {
    case missingToken
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Ajoute ton token PandaScore dans les réglages (⚙︎)."
        case .http(401):
            return "Token PandaScore invalide (401)."
        case .http(429):
            return "Trop de requêtes, réessaie dans un instant (429)."
        case .http(let code):
            return "Erreur serveur (\(code))."
        }
    }
}

/// Client minimal pour l'API REST PandaScore (CS2 = préfixe /csgo/).
actor PandaScoreService {
    static let shared = PandaScoreService()

    private let base = URL(string: "https://api.pandascore.co")!
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let iso = ISO8601DateFormatter()
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            if let date = iso.date(from: s) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Date: \(s)"))
        }
        return d
    }()

    private func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        guard !Config.pandaScoreToken.isEmpty else {
            throw APIError.missingToken
        }
        var comps = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(Config.pandaScoreToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.http(http.statusCode)
        }
        return try decoder.decode(T.self, from: data)
    }

    func runningMatches() async throws -> [Match] {
        try await get("/csgo/matches/running", query: ["per_page": "50"])
    }

    func upcomingMatches(teamID: Int? = nil) async throws -> [Match] {
        var q = ["per_page": "50", "sort": "scheduled_at"]
        if let teamID { q["filter[opponent_id]"] = String(teamID) }
        return try await get("/csgo/matches/upcoming", query: q)
    }

    func pastMatches(teamID: Int) async throws -> [Match] {
        try await get("/csgo/matches/past", query: [
            "per_page": "10",
            "filter[opponent_id]": String(teamID),
            "sort": "-begin_at"
        ])
    }

    func match(id: Int) async throws -> Match {
        try await get("/matches/\(id)")
    }

    func searchTeams(_ text: String) async throws -> [Team] {
        try await get("/csgo/teams", query: ["search[name]": text, "per_page": "30"])
    }
}
