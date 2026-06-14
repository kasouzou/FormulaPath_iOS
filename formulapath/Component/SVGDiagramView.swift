import Foundation
import SwiftUI
import WebKit

// SVG図形レンダリングをカプセル化するコンポーネント（疎結合の意識）
// JSONから渡されたSVG文字列を透明なWebView内で表示し、図形が必要な問題だけ自然に差し込めるようにするよ！
struct SVGDiagramView: View {
    let svg: String

    @State private var aspectRatio: CGFloat = 16.0 / 9.0

    var body: some View {
        SVGDiagramWebView(svg: svg, aspectRatio: $aspectRatio)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120, maxHeight: 260)
            // SwiftUI側の背景になじませるため、WebView自体は完全に透明にするよ
            .background(Color.clear)
    }
}

private struct SVGDiagramWebView: UIViewRepresentable {
    let svg: String
    @Binding var aspectRatio: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(aspectRatio: $aspectRatio)
    }

    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "svgMetrics")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)

        // 背景の完全透過設定
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        // 図形エリア内でスクロールやピンチズームが起きないように固定
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.panGestureRecognizer.isEnabled = false

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

                <style>
                    html, body {
                        margin: 0;
                        padding: 0;
                        width: 100%;
                        height: 100%;
                        overflow: hidden;
                        background-color: transparent;
                    }
                    body {
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        color: #1c1c1e;
                    }
                    #diagram {
                        width: 100%;
                        height: 100%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        background-color: transparent;
                    }
                    #diagram svg {
                        display: block;
                        width: 100%;
                        height: 100%;
                        max-width: 100%;
                        max-height: 100%;
                        background-color: transparent;
                    }
                    @media (prefers-color-scheme: dark) {
                        body { color: #f2f2f7; }
                    }
                </style>
            </head>
            <body>
                <div id="diagram"></div>
                <script>
                    var rawSVG = \(svg.safeJavaScriptStringLiteral);
                    var container = document.getElementById("diagram");
                    container.innerHTML = rawSVG;

                    function parseLength(value) {
                        if (!value) return null;
                        var number = parseFloat(String(value).replace("px", ""));
                        return Number.isFinite(number) && number > 0 ? number : null;
                    }

                    function reportAspectRatio() {
                        var svg = container.querySelector("svg");
                        if (!svg) return;

                        var ratio = null;
                        var viewBox = svg.getAttribute("viewBox");

                        if (viewBox) {
                            var values = viewBox.trim().split(/[\\s,]+/).map(Number);
                            if (values.length === 4 && values[2] > 0 && values[3] > 0) {
                                ratio = values[2] / values[3];
                            }
                        }

                        if (!ratio) {
                            var width = parseLength(svg.getAttribute("width"));
                            var height = parseLength(svg.getAttribute("height"));
                            if (width && height) {
                                ratio = width / height;
                            }
                        }

                        if (!ratio) {
                            ratio = 16 / 9;
                        }

                        svg.setAttribute("preserveAspectRatio", "xMidYMid meet");
                        window.webkit.messageHandlers.svgMetrics.postMessage(ratio);
                    }

                    requestAnimationFrame(reportAspectRatio);
                </script>
            </body>
            </html>
            """

        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        @Binding private var aspectRatio: CGFloat

        init(aspectRatio: Binding<CGFloat>) {
            self._aspectRatio = aspectRatio
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "svgMetrics" else { return }

            let ratio: CGFloat?
            if let number = message.body as? NSNumber {
                ratio = CGFloat(truncating: number)
            } else if let value = message.body as? Double {
                ratio = CGFloat(value)
            } else {
                ratio = nil
            }

            guard let ratio, ratio.isFinite, ratio > 0 else { return }

            DispatchQueue.main.async {
                self.aspectRatio = ratio
            }
        }
    }
}

private extension String {
    var safeJavaScriptStringLiteral: String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: [self]),
            let arrayLiteral = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }

        return String(arrayLiteral.dropFirst().dropLast())
            .replacingOccurrences(of: "</", with: "<\\/")
    }
}
