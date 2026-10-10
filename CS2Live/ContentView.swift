import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: MatchesViewModel
    @State private var showTeamPicker = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                if let error = vm.errorMessage {
                    Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
                }

                favoriteHeader

                if vm.hasFavorite {
                    Section("\(vm.favoriteTeamName) — en direct") {
                        if vm.favoriteLive.isEmpty {
                            Text("Pas de match en cours").foregroundStyle(.secondary)
                        } else {
                            ForEach(vm.favoriteLive) { matchLink($0) }
                        }
                    }
                }

                Section {
                    if vm.otherLive.isEmpty {
                        Text("Aucun autre match en direct").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.otherLive) { matchLink($0) }
                    }
                } header: {
                    HStack {
                        Text("Tous les matchs en direct")
                        Spacer()
                        Toggle("Twitch", isOn: $vm.onlyTwitch)
                            .toggleStyle(.button)
                            .font(.caption)
                            .tint(Theme.twitch)
                    }
                }

                Section(vm.hasFavorite ? "Prochains matchs de \(vm.favoriteTeamName)" : "Prochains matchs") {
                    if vm.upcoming.isEmpty {
                        Text("Rien de programmé").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.upcoming.prefix(15)) { matchLink($0) }
                    }
                }

                if vm.hasFavorite && !vm.recent.isEmpty {
                    Section("Derniers résultats") {
                        ForEach(vm.recent) { matchLink($0) }
                    }
                }

                if let last = vm.lastUpdate {
                    Section {
                        Text("Mis à jour \(last.formatted(date: .omitted, time: .standard)) · toutes les \(Int(Config.refreshInterval)) s")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("CS2 Live")
            .refreshable { await vm.refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showTeamPicker) { TeamPickerView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(for: Match.self) { MatchDetailView(matchID: $0.id, initial: $0) }
            .onAppear {
                if Config.pandaScoreToken.isEmpty { showSettings = true }
                else if !vm.hasFavorite { showTeamPicker = true }
            }
        }
    }

    @ViewBuilder private var favoriteHeader: some View {
        Section {
            Button { showTeamPicker = true } label: {
                HStack(spacing: 12) {
                    TeamLogo(url: URL(string: vm.favoriteTeamLogo), size: 40)
                    VStack(alignment: .leading) {
                        Text(vm.hasFavorite ? vm.favoriteTeamName : "Choisis ton équipe")
                            .font(.headline)
                        Text(vm.hasFavorite ? "Équipe favorite · touche pour changer" : "Pour être notifié de ses matchs")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "star.fill").foregroundStyle(Theme.accent)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func matchLink(_ m: Match) -> some View {
        NavigationLink(value: m) {
            MatchRow(match: m, favoriteID: vm.favoriteTeamID)
        }
    }
}

struct MatchRow: View {
    let match: Match
    let favoriteID: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if match.isLive {
                    Text("LIVE").font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.live, in: Capsule())
                } else if let date = match.scheduledAt ?? match.beginAt {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).day().hour().minute()))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Text(match.league?.name ?? "").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                Spacer()
                if match.isOnTwitch {
                    Image(systemName: "play.tv.fill").font(.caption).foregroundStyle(Theme.twitch)
                }
                Text(match.formatLabel).font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            teamLine(match.teamA)
            teamLine(match.teamB)
        }
        .padding(.vertical, 2)
    }

    private func teamLine(_ team: Team?) -> some View {
        HStack {
            TeamLogo(url: team?.imageURL, size: 20)
            Text(team?.name ?? "À déterminer")
                .fontWeight(team?.id == favoriteID ? .bold : .regular)
                .foregroundStyle(team?.id == favoriteID ? Theme.accent : .primary)
                .lineLimit(1)
            Spacer()
            if match.status != "not_started" {
                Text("\(match.score(for: team))").font(.body.monospacedDigit().bold())
            }
        }
    }
}

struct TeamLogo: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { img in
            img.resizable().scaledToFit()
        } placeholder: {
            Image(systemName: "shield.fill").resizable().scaledToFit().foregroundStyle(.gray.opacity(0.4))
        }
        .frame(width: size, height: size)
    }
}
