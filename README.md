# CS2 Live — app iOS (SwiftUI)

Suis les matchs CS2 diffusés sur Twitch, choisis ton équipe favorite et regarde les scores se mettre à jour en direct.

## Télécharger l'app
Chaque modification du code lance une compilation automatique sur un Mac de GitHub (onglet **Actions**).
Le fichier prêt à installer se trouve dans **Releases → latest → CS2Live.ipa**.

## Installer sur l'iPhone (depuis un PC Windows ou un Mac)
1. Installe **Sideloadly** (sideloadly.io) et, sur Windows, iTunes + iCloud version site Apple (pas Microsoft Store).
2. Branche l'iPhone, ouvre Sideloadly, glisse `CS2Live.ipa`, entre ton Apple ID, clique **Start**.
3. Sur l'iPhone : **Réglages → Général → VPN et gestion de l'appareil** → fais confiance à ton Apple ID.
4. iOS 16+ : active **Réglages → Confidentialité et sécurité → Mode développeur**, puis redémarre.
5. Ouvre l'app, colle ton token PandaScore (gratuit sur app.pandascore.co) dans ⚙︎, choisis ton équipe.

Avec un Apple ID gratuit, l'app expire au bout de **7 jours** : refais l'étape 2, ou active le rafraîchissement automatique en Wi-Fi dans Sideloadly.

## Fonctionnalités
- **Équipe favorite** : recherche parmi toutes les équipes CS2.
- **Matchs en direct** : ton équipe en haut, puis les autres (filtre « Twitch uniquement »).
- **Temps réel** : scores et maps rafraîchis toutes les 20 s, tirer pour actualiser.
- **Lecteur Twitch intégré**, choix de la chaîne, bouton pour ouvrir dans l'app Twitch.
- **Notifications** quand ton équipe passe en live et à chaque map terminée (app ouverte).

## Limites
- Le plan gratuit PandaScore donne le score en maps, pas round par round.
- Twitch a 2 à 4 min de décalage : le score affiché peut être en avance sur le stream.
- Notifications app fermée : impossible sans serveur de push.

## Compiler soi-même (Mac)
`brew install xcodegen && xcodegen generate`, puis ouvre `CS2Live.xcodeproj`.
