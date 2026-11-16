import SwiftUI
import WebKit

struct MarkdownWebView: UIViewRepresentable {
    let markdown: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.markdown != markdown else { return }
        context.coordinator.markdown = markdown
        do {
            webView.loadHTMLString(try MarkdownPage.html(for: markdown), baseURL: nil)
        } catch {
            webView.loadHTMLString(
                "<html><body><p>The bundled Markdown renderer could not be loaded.</p></body></html>",
                baseURL: nil
            )
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var markdown: String?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            if navigationAction.navigationType == .linkActivated {
                if ["https", "http", "mailto"].contains(url.scheme?.lowercased() ?? "") {
                    UIApplication.shared.open(url)
                } else if url.scheme == "about", url.fragment != nil {
                    decisionHandler(.allow)
                    return
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(url.scheme == "about" ? .allow : .cancel)
        }
    }
}

enum MarkdownPage {
    static func html(for markdown: String) throws -> String {
        let bundle = Bundle.main
        let templateURL = try resource("reader", extension: "html", in: bundle)
        let markedURL = try resource("marked", extension: "js", in: bundle)
        let purifierURL = try resource("purify", extension: "js", in: bundle)
        let template = try String(contentsOf: templateURL, encoding: .utf8)
        let marked = try String(contentsOf: markedURL, encoding: .utf8)
        let purifier = try String(contentsOf: purifierURL, encoding: .utf8)
        let nonce = UUID().uuidString
        let content = Data(markdown.utf8).base64EncodedString()
        return template
            .replacingOccurrences(of: "__NONCE__", with: nonce)
            .replacingOccurrences(of: "__MARKED__", with: marked)
            .replacingOccurrences(of: "__PURIFY__", with: purifier)
            .replacingOccurrences(of: "__MARKDOWN_BASE64__", with: content)
    }

    private static func resource(
        _ name: String, extension ext: String, in bundle: Bundle
    ) throws -> URL {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }
}
