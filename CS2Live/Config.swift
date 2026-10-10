import Foundation

enum Config {
    /// Intervalle de rafraîchissement des scores en direct (secondes).
    /// Le plan gratuit PandaScore autorise ~1000 requêtes/heure : 20 s est un bon compromis.
    static let refreshInterval: Double = 20

    /// Domaine "parent" exigé par le lecteur intégré Twitch.
    static let twitchEmbedParent = "localhost"

    /// Token PandaScore saisi dans les réglages de l'app (jamais dans le code : le dépôt est public).
    static var pandaScoreToken: String {
        get { UserDefaults.standard.string(forKey: "pandaScoreToken") ?? "" }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "pandaScoreToken") }
    }
}
