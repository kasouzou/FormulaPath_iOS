import SwiftUI
import WebKit


// 数式レンダリングをカプセル化するコンポーネント（疎結合の意識）
// 将来的にどのライブラリを採用しても、このViewの中身を書き換えるだけで全体の画面に影響を与えずに修正できるよ！
struct LaTeXView: View {
    let latex: String
    
    var body: some View {
        KaTeXWebView(latex: latex)
            // SwiftUI側の枠線や白背景、影のスタイルをそのまま活かすために、WebView自体は完全に透明にするよ
            .background(Color.clear)
    }
}

// 説明文の中に混ざった数式もKaTeXでインライン表示するためのコンポーネント
struct LaTeXTextView: View {
    let text: String
    var isError: Bool = false

    @State private var dynamicHeight: CGFloat = 44

    var body: some View {
        KaTeXTextWebView(text: text, isError: isError, dynamicHeight: $dynamicHeight)
            .frame(height: dynamicHeight)
            // SwiftUI側の余白や背景になじませるため、説明文用WebViewも透明にしておく
            .background(Color.clear)
    }
}

// WKWebViewをSwiftUIで利用するための橋渡し構造体
private struct KaTeXWebView: UIViewRepresentable {
    let latex: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // 背景の完全透過設定
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // ユーザーが数式を間違えてピンチイン・アウトしたりスクロールしたりしないように固定
        webView.scrollView.isScrollEnabled = false
        
        return webView
    }
    
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let resources = KaTeXResources.load() else {
            print("エラー: KaTeXリソースがBundle内に見つかりません。")
            return
        }
        
        let htmlString = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8"> <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                
                <style>
                    \(resources.css)
                </style>
                
                <style>
                    body {
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        margin: 0;
                        padding: 0 8px;
                        background-color: transparent;
                        color: black;
                    }
                    @media (prefers-color-scheme: dark) {
                        body { color: white; }
                    }
                    .katex-display {
                        margin: 0 !important;
                        font-size: 1.1em;
                    }
                </style>
            </head>
            <body>
                <div id="math"></div>
                <script>
                    \(resources.javascript)

                    var mathExpression = \(latex.javaScriptStringLiteral);

                    if (typeof katex === 'undefined') {
                        document.getElementById("math").innerText = "KaTeX Load Error!";
                    } else {
                        try {
                            var mathDiv = document.getElementById("math");
                            katex.render(mathExpression, mathDiv, {
                                displayMode: true,
                                throwOnError: false
                            });

                            // 💡 【ResizeObserverを使った極めて堅牢な自動縮小ロジック】
                            // SwiftUIのレイアウトが確定し、WebViewの実際のサイズが決まった瞬間を監視して確実に縮小させるよ！
                            var doScale = function() {
                                var mathElement = mathDiv.querySelector('.katex');
                                var displayElement = mathDiv.querySelector('.katex-display');
                                if (!mathElement || !displayElement) return;

                                // 一度スケールをリセットして本来のサイズを正確に計測
                                displayElement.style.transform = "none";
                                
                                var maxWidth = window.innerWidth - 16; // 左右のpadding分を考慮
                                var mathWidth = mathElement.scrollWidth;

                                if (mathWidth > maxWidth && maxWidth > 0) {
                                    var scale = maxWidth / mathWidth;
                                    displayElement.style.transform = "scale(" + scale + ")";
                                    displayElement.style.transformOrigin = "center center"; // 中央基準で綺麗に縮小
                                }
                            };

                            // WebViewのサイズ変化（初期配置されるタイミングなど）を検知するオブザーバーを登録
                            var observer = new ResizeObserver(function() {
                                doScale();
                            });
                            observer.observe(document.body);

                            // 初回レンダリング時にも即時実行
                            doScale();

                        } catch (e) {
                            console.error(e);
                        }
                    }
                </script>
            </body>
            </html>
            """
        
        uiView.loadHTMLString(htmlString, baseURL: resources.baseURL)
    }
}

// 日本語の説明文とTeX数式を同じ行の中で表示するための橋渡し構造体
private struct KaTeXTextWebView: UIViewRepresentable {
    let text: String
    let isError: Bool
    @Binding var dynamicHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(dynamicHeight: $dynamicHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "heightObserver")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let resources = KaTeXResources.load() else {
            print("エラー: KaTeXリソースがBundle内に見つかりません。")
            return
        }

        let htmlString = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

                <style>
                    \(resources.css)
                </style>

                <style>
                    html, body {
                        margin: 0;
                        padding: 0;
                        background-color: transparent;
                        overflow: hidden;
                    }
                    body {
                        color: \(isError ? "#ff3b30" : "#6c6c70");
                        font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
                        font-size: 15px;
                        font-weight: 400;
                        line-height: 1.7;
                        text-align: center;
                    }
                    #content {
                        box-sizing: border-box;
                        width: 100%;
                        padding: 0 8px;
                    }
                    .inline-math {
                        display: inline-block;
                        vertical-align: -0.16em;
                        margin: 0 0.08em;
                    }
                    .inline-math .katex {
                        font-size: 1.05em;
                    }
                    .katex {
                        color: inherit;
                    }
                    @media (prefers-color-scheme: dark) {
                        body { color: \(isError ? "#ff453a" : "#aeaeb2"); }
                    }
                </style>
            </head>
            <body>
                <div id="content"></div>
                <script>
                    \(resources.javascript)

                    var rawText = \(text.javaScriptStringLiteral);

                    function escapeHTML(value) {
                        return value
                            .replace(/&/g, "&amp;")
                            .replace(/</g, "&lt;")
                            .replace(/>/g, "&gt;")
                            .replace(/"/g, "&quot;")
                            .replace(/'/g, "&#039;");
                    }

                    function shouldTreatAsMath(value) {
                        var trimmed = value.trim();
                        if (!trimmed) return false;
                        if (/\\\\[a-zA-Z]+/.test(trimmed)) return true;
                        if (/[=<>^_]/.test(trimmed) && /[a-zA-Z0-9]/.test(trimmed)) return true;
                        if (/^[({]?\\s*[a-zA-Z0-9]+\\s*[+\\-*/]\\s*[a-zA-Z0-9]/.test(trimmed)) return true;
                        if (/^[({]?\\s*[a-zA-Z]\\s*[)}]?\\^/.test(trimmed)) return true;
                        if (/^[a-zA-Z]+\\([a-zA-Z0-9+\\-*/^_\\s,]*\\)/.test(trimmed)) return true;
                        return false;
                    }

                    function readExplicitMath(source, index) {
                        var starts = [
                            { open: "$", close: "$", offset: 1 },
                            { open: "\\\\(", close: "\\\\)", offset: 2 },
                            { open: "\\\\[", close: "\\\\]", offset: 2 }
                        ];

                        for (var i = 0; i < starts.length; i++) {
                            var marker = starts[i];
                            if (source.slice(index, index + marker.open.length) !== marker.open) continue;

                            var end = source.indexOf(marker.close, index + marker.offset);
                            if (end === -1) return null;

                            return {
                                value: source.slice(index + marker.offset, end),
                                length: end + marker.close.length - index
                            };
                        }

                        return null;
                    }

                    function readImplicitMath(source, index) {
                        var remaining = source.slice(index);
                        var patterns = [
                            /^\\\\[a-zA-Z]+(?:\\\\[a-zA-Z]+|\\{[^{}]*\\}|\\[[^\\[\\]]*\\]|[a-zA-Z0-9_\\^=<>+\\-*/().,!]|\\s)*(?=\\s|[。、，、。「」『』（）]|$)/,
                            /^\\([a-zA-Z0-9\\s+\\-*/]+\\)\\^[a-zA-Z0-9{}]+/,
                            /^\\([^（）)]*[a-zA-Z0-9\\\\][^（）)]*[=<>^_+\\-*/][^（）)]*\\)/,
                            /^[a-zA-Z0-9{}_^().\\\\!\\s+\\-*/]+(?:=|->|>|<)[a-zA-Z0-9{}_^().\\\\!\\s+\\-*/]+/,
                            /^[a-zA-Z]+\\([a-zA-Z0-9+\\-*/^_\\s,]*\\)(?:\\^[a-zA-Z0-9{}]+)?/,
                            /^[a-zA-Z0-9]+\\^[a-zA-Z0-9{}]+/
                        ];

                        for (var i = 0; i < patterns.length; i++) {
                            var match = remaining.match(patterns[i]);
                            if (!match) continue;

                            var value = match[0].trim();
                            if (!shouldTreatAsMath(value)) continue;

                            return {
                                value: value,
                                length: match[0].length
                            };
                        }

                        return null;
                    }

                    function renderMixedText(source) {
                        var content = document.getElementById("content");
                        content.textContent = "";

                        var textBuffer = "";

                        function flushText() {
                            if (!textBuffer) return;
                            content.appendChild(document.createTextNode(textBuffer));
                            textBuffer = "";
                        }

                        function appendMath(expression) {
                            flushText();

                            var span = document.createElement("span");
                            span.className = "inline-math";

                            try {
                                katex.render(expression.trim(), span, {
                                    displayMode: false,
                                    throwOnError: false
                                });
                            } catch (error) {
                                span.innerHTML = escapeHTML(expression);
                            }

                            content.appendChild(span);
                        }

                        for (var index = 0; index < source.length;) {
                            var explicitMath = readExplicitMath(source, index);
                            if (explicitMath) {
                                appendMath(explicitMath.value);
                                index += explicitMath.length;
                                continue;
                            }

                            var implicitMath = readImplicitMath(source, index);
                            if (implicitMath) {
                                appendMath(implicitMath.value);
                                index += implicitMath.length;
                                continue;
                            }

                            textBuffer += source[index];
                            index += 1;
                        }

                        flushText();
                    }

                    function postHeight() {
                        var height = Math.ceil(document.documentElement.scrollHeight);
                        window.webkit.messageHandlers.heightObserver.postMessage(height);
                    }

                    if (typeof katex === "undefined") {
                        document.getElementById("content").innerText = rawText;
                    } else {
                        renderMixedText(rawText);
                    }

                    var observer = new ResizeObserver(function() {
                        postHeight();
                    });
                    observer.observe(document.getElementById("content"));

                    requestAnimationFrame(postHeight);
                    setTimeout(postHeight, 80);
                </script>
            </body>
            </html>
            """

        uiView.loadHTMLString(htmlString, baseURL: resources.baseURL)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        @Binding private var dynamicHeight: CGFloat

        init(dynamicHeight: Binding<CGFloat>) {
            self._dynamicHeight = dynamicHeight
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "heightObserver" else { return }

            let height: CGFloat?
            if let number = message.body as? NSNumber {
                height = CGFloat(truncating: number)
            } else if let value = message.body as? Double {
                height = CGFloat(value)
            } else {
                height = nil
            }

            guard let height else { return }

            DispatchQueue.main.async {
                self.dynamicHeight = max(28, height)
            }
        }
    }
}

private struct KaTeXResources {
    let baseURL: URL
    let css: String
    let javascript: String

    static func load() -> KaTeXResources? {
        if let folderURL = Bundle.main.url(forResource: "katex", withExtension: nil),
           let resources = load(from: folderURL, flattenFontPaths: false) {
            return resources
        }

        guard
            let cssURL = Bundle.main.url(forResource: "katex.min", withExtension: "css"),
            let jsURL = Bundle.main.url(forResource: "katex.min", withExtension: "js")
        else {
            return nil
        }

        return load(
            baseURL: Bundle.main.bundleURL,
            cssURL: cssURL,
            jsURL: jsURL,
            flattenFontPaths: true
        )
    }

    private static func load(from folderURL: URL, flattenFontPaths: Bool) -> KaTeXResources? {
        load(
            baseURL: folderURL,
            cssURL: folderURL.appendingPathComponent("katex.min.css"),
            jsURL: folderURL.appendingPathComponent("katex.min.js"),
            flattenFontPaths: flattenFontPaths
        )
    }

    private static func load(baseURL: URL, cssURL: URL, jsURL: URL, flattenFontPaths: Bool) -> KaTeXResources? {
        do {
            var css = try String(contentsOf: cssURL, encoding: .utf8)
            let javascript = try String(contentsOf: jsURL, encoding: .utf8)

            if flattenFontPaths {
                css = css.replacingOccurrences(of: "url(fonts/", with: "url(")
            }

            return KaTeXResources(baseURL: baseURL, css: css, javascript: javascript)
        } catch {
            print("エラー: KaTeXリソースを読み込めません: \(error)")
            return nil
        }
    }
}

private extension String {
    var javaScriptStringLiteral: String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: [self]),
            let arrayLiteral = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }

        return String(arrayLiteral.dropFirst().dropLast())
    }
}
