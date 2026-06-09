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
        // SwiftからJavaScriptに文字列を渡す時に、バックスラッシュ（\）が消えないようにエスケープを調整するよ
        let escapedLaTeX = latex.replacingOccurrences(of: "\\", with: "\\\\")
        
        // KaTeXのCDNを利用したHTML文字列（ライトモード・ダークモードの自動切り替え付き）
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
            <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
            <style>
                body {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    padding: 0 8px;
                    background-color: transparent;
                    /* iOSのライト/ダークモードに合わせて文字色を自動で切り替える設定だよ */
                    color: black;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: white;
                    }
                }
                .katex-display {
                    margin: 0 !important;
                    font-size: 1.1em; /* 視認性を上げるために少しだけ大きく調整 */
                }
            </style>
        </head>
        <body>
            <div id="math"></div>
            <script>
                document.addEventListener("DOMContentLoaded", function() {
                    var mathExpression = "\(escapedLaTeX)";
                    katex.render(mathExpression, document.getElementById("math"), {
                        displayMode: true,
                        throwOnError: false
                    });
                });
            </script>
        </body>
        </html>
        """
        
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}
