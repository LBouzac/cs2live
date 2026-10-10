import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: MatchesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var token = Config.pandaScoreToken

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Colle ton token ici", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Token PandaScore")
                } footer: {
                    Text("Gratuit sur app.pandascore.co, dans ton tableau de bord. Il reste uniquement sur ce téléphone.")
                }

                Section {
                    Button("Choisir l'équipe favorite") {
                        save()
                    }
                } footer: {
                    Text("Les scores se mettent à jour toutes les \(Int(Config.refreshInterval)) s tant que l'app est ouverte. Le stream Twitch a 2 à 4 minutes de retard sur le score affiché.")
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Enregistrer") { save() } }
                ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } }
            }
        }
    }

    private func save() {
        Config.pandaScoreToken = token
        Task { await vm.refresh() }
        dismiss()
    }
}
