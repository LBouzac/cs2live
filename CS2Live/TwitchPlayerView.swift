import SwiftUI
import WebKit

/// Lecteur Twitch intégré (iframe officielle player.twitch.tv dans une WKWebView).
struct TwitchPlayerView: UIViewRepresentable {
    let channel: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        guard context.coordinator.loadedChannel != channel else { return }
        context.coordinator.loadedChannel = channel
        let parent = Config.twitchEmbedParent
        let html = """
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <style>html,body{margin:0;height:100%;background:#000}iframe{border:0;width:100%;height:100%}</style>
        </head><body>
        <iframe src="https://player.twitch.tv/?channel=\(channel)&parent=\(parent)&muted=false&autoplay=true"
                allowfullscreen allow="autoplay; fullscreen"></iframe>
        </body></html>
        """
        web.loadHTMLString(html, baseURL: URL(string: "https://\(parent)"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var loadedChannel: String? }
}
