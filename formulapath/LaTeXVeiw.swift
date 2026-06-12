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
