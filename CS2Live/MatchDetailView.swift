import SwiftUI

struct MatchDetailView: View {
    let matchID: Int
    @State var match: Match
    @State private var selectedStream: MatchStream?
    @Environment(\.openURL) private var openURL

    init(matchID: Int, initial: Match) {
        self.matchID = matchID
        _match = State(initialValue: initial)
        _selectedStream = State(initialValue: initial.twitchStreams.first)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Lecteur Twitch intégré
                if match.isLive, let channel = selectedStream?.twitchChannel {
                    TwitchPlayerView(channel: channel)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                scoreboard

                if !match.twitchStreams.isEmpty { streamsSection }

                if let games = match.games, !games.isEmpty { mapsSection(games) }
            }
            .padding()
        }
        .navigationTitle(match.league?.name ?? "Match")
        .navigationBarTitleDisplayMode(.inline)
        .task { await liveLoop() }
    }

    // MARK: - Sections

    private var scoreboard: some View {
        VStack(spacing: 10) {
            Text(match.serie?.fullName ?? match.tournament?.name ?? "")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                teamColumn(match.teamA)
                VStack {
                    Text("\(match.score(for: match.teamA)) : \(match.score(for: match.teamB))")
                        .font(.system(size: 40, weight: .heavy, design: .rounded).monospacedDigit())
                    Group {
                        if match.isLive {
                            Label(match.currentMapLabel ?? "En direct", systemImage: "dot.radiowaves.left.and.right")
                                .foregroundStyle(Theme.live)
                        } else if match.status == "not_started", let d = match.scheduledAt {
                            Text(d.formatted(date: .abbreviated, time: .shortened))
                        } else {
                            Text("Terminé")
                        }
                    }
                    .font(.caption.bold())
                    Text(match.formatLabel).font(.caption2.monospaced()).foregroundStyle(.secondary)
                }
                teamColumn(match.teamB)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func teamColumn(_ team: Team?) -> some View {
        VStack(spacing: 6) {
            TeamLogo(url: team?.imageURL, size: 56)
            Text(team?.acronym ?? team?.name ?? "TBD").font(.headline).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var streamsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Streams Twitch").font(.headline)
            ForEach(match.twitchStreams) { s in
                HStack {
                    Image(systemName: "play.tv.fill").foregroundStyle(Theme.twitch)
                    Text(s.twitchChannel ?? "").fontWeight(s == selectedStream ? .bold : .regular)
                    if let lang = s.language { Text(lang.uppercased()).font(.caption2).foregroundStyle(.secondary) }
                    if s.official == true { Text("officiel").font(.caption2).foregroundStyle(.secondary) }
                    Spacer()
                    if match.isLive {
                        Button("Regarder") { selectedStream = s }.buttonStyle(.bordered).tint(Theme.twitch)
                    }
                    Button { openInTwitch(s) } label: { Image(systemName: "arrow.up.forward.app") }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func mapsSection(_ games: [Game]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Maps").font(.headline)
            ForEach(games.sorted { $0.position < $1.position }) { g in
                HStack {
                    Text("Map \(g.position)")
                    Spacer()
                    switch g.status {
                    case "running": Text("En cours").foregroundStyle(Theme.live)
                    case "finished":
                        let winner = [match.teamA, match.teamB].compactMap { $0 }.first { $0.id == g.winner?.id }
                        Text("Gagnée par \(winner?.acronym ?? winner?.name ?? "?")").foregroundStyle(.secondary)
                    default: Text("À venir").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Temps réel

    private func liveLoop() async {
        while !Task.isCancelled {
            if let fresh = try? await PandaScoreService.shared.match(id: matchID) {
                match = fresh
                if selectedStream == nil { selectedStream = fresh.twitchStreams.first }
            }
            guard match.status == "running" || match.status == "not_started" else { return }
            try? await Task.sleep(for: .seconds(Config.refreshInterval))
        }
    }

    private func openInTwitch(_ s: MatchStream) {
        guard let channel = s.twitchChannel else { return }
        // Ouvre l'app Twitch si installée, sinon le site.
        guard let app = URL(string: "twitch://stream/\(channel)"),
              let web = URL(string: "https://www.twitch.tv/\(channel)") else { return }
        openURL(app) { accepted in
            if !accepted { openURL(web) }
        }
    }
}
