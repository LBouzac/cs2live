import SwiftUI

struct TeamPickerView: View {
    @EnvironmentObject var vm: MatchesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [Team] = []
    @State private var loading = false
    @State private var error: String?

    private let suggestions = ["Vitality", "Natus Vincere", "FaZe", "G2", "Spirit", "MOUZ", "Falcons", "The MongolZ", "Team Liquid", "FURIA"]

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section("Suggestions") {
                        ForEach(suggestions, id: \.self) { name in
                            Button(name) { query = name }
                        }
                    }
                }
                if let error { Text(error).foregroundStyle(.orange) }
                ForEach(results) { team in
                    Button {
                        vm.setFavorite(team)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            TeamLogo(url: team.imageURL, size: 32)
                            VStack(alignment: .leading) {
                                Text(team.name).foregroundStyle(.primary)
                                if let a = team.acronym { Text(a).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            if team.id == vm.favoriteTeamID {
                                Image(systemName: "star.fill").foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }
            .overlay { if loading { ProgressView() } }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Rechercher une équipe")
            .task(id: query) { await search() }
            .navigationTitle("Équipe favorite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } } }
        }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else { results = []; return }
        try? await Task.sleep(for: .milliseconds(350))   // anti-rebond
        guard !Task.isCancelled else { return }
        loading = true
        defer { loading = false }
        do {
            results = try await PandaScoreService.shared.searchTeams(text)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
