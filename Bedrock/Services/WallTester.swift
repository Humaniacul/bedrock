import Foundation
import WebKit

/// S4's silent check (SPEC.md S4): after the person closes the test page, load
/// the same page in a background web view. Screen Time's web filter applies to
/// WebKit, so a held wall either fails the load or serves Apple's restriction
/// page instead of ours.
///
/// - Our page loads (its title carries the marker) → `.opened`.
/// - It doesn't, and the internet is reachable → `.held`.
/// - The internet isn't reachable either → `.unverified`.
@MainActor
final class WallTester: NSObject, WKNavigationDelegate {
    /// The test page's `<title>`: the only page that carries it is ours, so seeing
    /// it means the wall let it through.
    static let marker = "Bedrock wall test"

    private var webView: WKWebView?
    private var continuation: CheckedContinuation<Bool?, Never>?
    private var timeout: Task<Void, Never>?

    func run(url: URL = WallTestPage.url) async -> WallTestOutcome {
        let pageOpened = await loadTestPage(url)
        if pageOpened == true { return .opened }
        return await Self.isOnline() ? .held : .unverified
    }

    /// true = our page rendered; false = blocked or replaced; nil = timed out.
    private func loadTestPage(_ url: URL) async -> Bool? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.navigationDelegate = self
            self.webView = webView
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10))
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(12))
                self?.resolve(nil)
            }
        }
    }

    private func resolve(_ value: Bool?) {
        guard let continuation else { return }
        self.continuation = nil
        timeout?.cancel()
        webView?.stopLoading()
        webView = nil
        continuation.resume(returning: value)
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            let title = (try? await webView.evaluateJavaScript("document.title")) as? String
            resolve(title?.contains(Self.marker) == true)
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in resolve(false) }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in resolve(false) }
    }

    /// A plain request to a page the wall never blocks, to tell “blocked” from “offline”.
    private static func isOnline() async -> Bool {
        var request = URLRequest(url: URL(string: "https://www.apple.com/library/test/success.html")!,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 8)
        request.httpMethod = "HEAD"
        guard let (_, response) = try? await URLSession.shared.data(for: request) else { return false }
        return (response as? HTTPURLResponse).map { (200..<400).contains($0.statusCode) } ?? false
    }
}
