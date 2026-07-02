# FormulaPath 数式レンダリング（KaTeX）実装マニュアル

このマニュアルは、FormulaPath アプリ内で数式をきれいに表示するための実装方法をまとめたものです。

現在の実装では、SwiftUI の画面から直接数式を描画するのではなく、`WKWebView` の中でローカル同梱した KaTeX を動かし、その結果を SwiftUI の部品として表示しています。

---

## 1. 全体構成

数式レンダリングは、主に以下のファイルで構成されています。

```text
formulapath/formulapath/
├── LaTeXVeiw.swift
├── katex/
│   ├── katex.min.css
│   ├── katex.min.js
│   └── fonts/
├── GamePlayView.swift
├── Component/
│   └── ChoiceButton.swift
├── high_school_quizzes.json
├── junior_high_quizzes.json
└── university_quizzes.json
```

役割は以下の通りです。

| ファイル | 役割 |
| --- | --- |
| `LaTeXVeiw.swift` | KaTeX と `WKWebView` を SwiftUI から使えるようにする中心ファイル |
| `katex/` | KaTeX 本体、CSS、フォントをアプリ内に同梱するローカルリソース |
| `GamePlayView.swift` | 問題画面で数式ボードと説明文を表示する |
| `ChoiceButton.swift` | 選択肢ボタン内でも数式を表示する |
| `*_quizzes.json` | 問題、説明文、選択肢の LaTeX 文字列を持つデータ |

---

## 2. 実装の考え方

FormulaPath では、数式表示を `LaTeXView` と `LaTeXTextView` に分けています。

### `LaTeXView`

単独の数式を大きく表示するためのコンポーネントです。

主な用途は以下です。

* 問題画面の現在の式
* 選択肢ボタン内の式
* 長い選択肢をシートで拡大表示するときの式

使用例:

```swift
LaTeXView(latex: viewModel.currentEquation)
    .frame(maxWidth: .infinity)
    .frame(height: 220)
```

### `LaTeXTextView`

日本語の説明文の中に、インライン数式を混ぜて表示するためのコンポーネントです。

使用例:

```swift
LaTeXTextView(text: step.explanation, isError: viewModel.showWrongAnswerEffect)
    .padding(.horizontal, 8)
```

説明文では、以下のような文字列を自然に表示できます。

```json
"explanation": "第 $n$ 項では公差が $n-1$ 回足されています。"
```

---

## 3. KaTeX リソースの配置

KaTeX は CDN から読み込まず、アプリ内の `katex/` フォルダに同梱しています。

```text
katex/
├── katex.min.css
├── katex.min.js
└── fonts/
```

この方式にしている理由は以下です。

* オフラインでも数式を表示できる
* ネットワーク状態に左右されない
* App Store 審査や実機環境で外部 CDN 依存を避けられる
* KaTeX のバージョンをアプリ側で固定できる

`LaTeXVeiw.swift` の `KaTeXResources.load()` が、Bundle 内から以下を読み込みます。

* `katex.min.css`
* `katex.min.js`
* `fonts/` 以下の KaTeX フォント

通常は `Bundle.main.url(forResource: "katex", withExtension: nil)` で `katex` フォルダを見つけます。

もし Xcode のリソース登録状態によって CSS/JS が Bundle 直下に展開されている場合は、フォールバックとして `katex.min.css` と `katex.min.js` を個別に探します。その場合は CSS 内の `url(fonts/...)` を `url(...)` に補正する処理も入っています。

---

## 4. `LaTeXView` の表示フロー

`LaTeXView` は、単独の数式を中央寄せで表示するための部品です。

処理の流れは以下です。

1. SwiftUI 側から `LaTeXView(latex: "...")` を呼ぶ
2. 内部で `KaTeXWebView` を作る
3. `WKWebView` を透明背景、スクロール無効で作成する
4. Bundle から KaTeX の CSS/JS を読み込む
5. HTML 文字列を組み立てる
6. JavaScript で `katex.render()` を実行する
7. `uiView.loadHTMLString(htmlString, baseURL: resources.baseURL)` で WebView に表示する

KaTeX の実行部分は以下の形です。

```javascript
katex.render(mathExpression, mathDiv, {
    displayMode: true,
    throwOnError: false
});
```

重要な設定は以下です。

| 設定 | 意味 |
| --- | --- |
| `displayMode: true` | 独立した大きめの数式として表示する |
| `throwOnError: false` | LaTeX に多少の不備があっても画面をクラッシュさせない |
| `backgroundColor = .clear` | SwiftUI 側の背景やカードデザインになじませる |
| `scrollView.isScrollEnabled = false` | WebView 内スクロールを防ぐ |
| `maximum-scale=1.0, user-scalable=no` | ピンチズームを防ぐ |

---

## 5. 長い数式の自動縮小

`LaTeXView` では、数式が横にはみ出さないように JavaScript 側で自動縮小しています。

実装のポイントは `ResizeObserver` です。

```javascript
var observer = new ResizeObserver(function() {
    doScale();
});
observer.observe(document.body);
```

`doScale()` は以下の順で動きます。

1. KaTeX が生成した `.katex` 要素を探す
2. WebView の表示可能幅を `window.innerWidth - 16` で計算する
3. 数式の本来の幅 `mathElement.scrollWidth` を測る
4. 数式が表示可能幅より大きければ `transform: scale(...)` で縮小する
5. `transformOrigin = "center center"` にして中央基準で縮小する

これにより、分数、総和、長い等式などがボード外にはみ出しにくくなります。

---

## 6. `LaTeXTextView` の表示フロー

`LaTeXTextView` は、日本語説明文とインライン数式を混ぜるための部品です。

処理の流れは以下です。

1. SwiftUI 側から `LaTeXTextView(text: step.explanation)` を呼ぶ
2. 内部で `KaTeXTextWebView` を作る
3. `WKUserContentController` に `heightObserver` を登録する
4. HTML 内の JavaScript で説明文を解析する
5. 数式部分だけ `katex.render(..., displayMode: false)` で描画する
6. WebView 内の高さを JavaScript から Swift に通知する
7. SwiftUI 側の `dynamicHeight` を更新して、説明文が切れない高さにする

インライン数式の実行部分は以下の形です。

```javascript
katex.render(expression.trim(), span, {
    displayMode: false,
    throwOnError: false
});
```

`displayMode: false` にしているため、文章の中に自然に数式が入ります。

---

## 7. 説明文内の数式の書き方

説明文では、明示的な数式区切りを使うのが最も安全です。

推奨:

```json
"explanation": "第 $n$ 項では公差が $n-1$ 回足されています。"
```

または:

```json
"explanation": "ここで \\(a_n=a_1+(n-1)d\\) と表せます。"
```

ブロック風に明示する場合:

```json
"explanation": "次の関係を使います: \\[S_n=\\frac{n(a_1+a_n)}{2}\\]"
```

現在の `LaTeXTextView` には、明示的な `$...$` や `\\(...\\)` だけでなく、簡単な式を自動検出する処理もあります。ただし、自動検出は文章との境界が曖昧になることがあるため、新しい問題データでは `$...$` を使うのを基本にしてください。

---

## 8. JSON に数式を書くときのルール

JSON 内では、LaTeX のバックスラッシュを `\\` として書きます。

例:

```json
{
  "formula": "S_n=\\frac{n(a_1+a_n)}{2}",
  "choices": [
    "S_n=n(a_1+a_n)",
    "S_n=\\frac{a_1+a_n}{2}",
    "S_n=\\frac{n(a_1+a_n)}{2}",
    "S_n=\\frac{n(a_1-a_n)}{2}"
  ]
}
```

よく使う記法:

| 表示したいもの | JSON に書く文字列 |
| --- | --- |
| 分数 | `"\\frac{a}{b}"` |
| 平方根 | `"\\sqrt{x}"` |
| 添字 | `"a_n"` |
| 上付き | `"x^2"` |
| 上付きのまとまり | `"r^{n-1}"` |
| 省略記号 | `"\\cdots"` |
| 空白 | `"\\quad"` |
| 掛け算記号 | `"\\times"` |
| プラスマイナス | `"\\pm"` |
| 本文テキスト | `"\\text{は公差}"` |

注意点:

* JSON では `\frac` ではなく `\\frac` と書く
* `r^n-1` は `r^n - 1` と解釈されるため、指数全体は `r^{n-1}` と書く
* 日本語を数式内に入れる場合は `\\text{...}` を使う
* 説明文内の数式は `$...$` で囲む

---

## 9. Swift コードに数式を書くときのルール

Swift の通常文字列で LaTeX を書く場合も、バックスラッシュのエスケープが必要です。

```swift
LaTeXView(latex: "S_n=\\frac{n(a_1+a_n)}{2}")
```

長い数式を Swift に直接書く場合は、Raw String を使うと読みやすくなります。

```swift
LaTeXView(latex: #"S_n=\frac{n(a_1+a_n)}{2}"#)
```

ただし、現在の問題データは基本的に JSON から読み込む構成なので、新しい問題を追加する場合は Swift に直接書くより JSON を編集する方が自然です。

---

## 10. JavaScript へ安全に文字列を渡す方法

`LaTeXVeiw.swift` では、Swift の文字列を JavaScript に直接埋め込まず、`javaScriptStringLiteral` を通して安全な文字列リテラルに変換しています。

```swift
var mathExpression = \(latex.javaScriptStringLiteral);
```

内部では `JSONSerialization` を使い、文字列を JavaScript 文字列として安全に扱える形にしています。

この処理が必要な理由は以下です。

* `\` を壊さず JavaScript に渡すため
* `"` や改行を含む文字列で HTML/JS が壊れないようにするため
* 説明文や選択肢に日本語や記号が入っても安全に表示するため

新しく WebView 内 JavaScript に Swift 文字列を渡す処理を追加する場合も、同じ拡張を使ってください。

---

## 11. 問題画面での使われ方

`GamePlayView.swift` では、説明文、図形、数式ボードの順で表示しています。

```swift
LaTeXTextView(text: step.explanation, isError: viewModel.showWrongAnswerEffect)

if let diagramSVG = viewModel.currentDiagramSVG {
    SVGDiagramView(svg: diagramSVG)
}

if viewModel.shouldShowCurrentEquation {
    equationBoard
}
```

数式ボード本体は `equationBoard` 内で `LaTeXView` を使っています。

```swift
LaTeXView(latex: viewModel.currentEquation)
    .frame(maxWidth: .infinity)
    .frame(height: viewModel.currentDiagramSVG == nil ? 220 : 160)
```

図形がある場合は数式ボードを少し低くし、画面全体のバランスを取っています。

---

## 12. 選択肢ボタンでの使われ方

`ChoiceButton.swift` では、短い選択肢はボタン内に直接 `LaTeXView` を表示します。

```swift
LaTeXView(latex: text)
    .allowsHitTesting(false)
```

`allowsHitTesting(false)` は重要です。これがないと、ボタンの中にある `WKWebView` がタップを横取りし、Button のタップ処理が反応しにくくなることがあります。

長い数式の場合は、ボタン内に無理に詰め込まず、「選択肢を見る」ボタンとして表示し、シート内で大きく表示します。

長い数式と判定する主な条件:

* 2列ボタンで 12 文字を超える
* `=` を含む
* `\\to` や `\\rightarrow` を含む
* 全幅ボタンで 28 文字を超える
* `\\frac` や `\\sqrt` を含む

---

## 13. 新しい問題で数式をきれいに表示する手順

### 手順1: `formula` に最終表示したい LaTeX を書く

```json
"formula": "a_n=a_1+(n-1)d"
```

### 手順2: `choices` に選択肢の LaTeX を書く

```json
"choices": [
  "a_n=a_1+nd",
  "a_n=na_1+d",
  "a_n=a_1+(n-1)d",
  "a_n=a_1d^{n-1}"
]
```

### 手順3: 説明文の中の数式は `$...$` で囲む

```json
"explanation": "第 $n$ 項では $d$ が $n-1$ 回足されています。"
```

### 手順4: 分数やルートなどは LaTeX コマンドを使う

```json
"formula": "x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}"
```

### 手順5: 実機またはシミュレータで確認する

確認する観点:

* 数式が表示されるか
* 横にはみ出していないか
* 説明文の高さが切れていないか
* 選択肢ボタンがタップできるか
* ダークモードで文字色が見えるか
* 長い選択肢がシート表示に切り替わるか

---

## 14. よくあるトラブルと対応

### 数式がそのまま文字列として表示される

原因候補:

* KaTeX リソースが Bundle に含まれていない
* `katex.min.js` または `katex.min.css` が見つからない
* JSON のバックスラッシュが不足している

確認すること:

* Xcode の Copy Bundle Resources に `katex` フォルダが含まれているか
* `formulapath/formulapath/katex/katex.min.js` が存在するか
* JSON で `\frac` ではなく `\\frac` と書いているか

### フォントが崩れる

原因候補:

* `katex/fonts/` が Bundle に入っていない
* CSS からフォントファイルへの相対パスが合っていない

確認すること:

* `katex/fonts/` 以下の `.woff2`, `.woff`, `.ttf` がプロジェクトに含まれているか
* `KaTeXResources.load()` が `baseURL` に `katex` フォルダを渡せているか

### 数式が横にはみ出す

原因候補:

* 数式が非常に長い
* WebView の幅が確定する前に計測されている
* `ResizeObserver` が期待通り動いていない

対応:

* 長い式は `\\begin{aligned}` などで分割できないか検討する
* 選択肢の場合は `ChoiceButton` のシート表示に逃がす
* `LaTeXView` の高さを少し増やす

### ボタンがタップできない

原因候補:

* ボタン内の `WKWebView` がタップイベントを受け取っている

対応:

* `ChoiceButton` 内の `LaTeXView` に `.allowsHitTesting(false)` が付いているか確認する

### 説明文の下が切れる

原因候補:

* `LaTeXTextView` の高さ通知が遅れている
* 非常に長い説明文で高さが不足している

対応:

* `heightObserver` の `postHeight()` が呼ばれているか確認する
* `dynamicHeight` の最小値や余白を調整する
* 説明文を短く分割する

---

## 15. 実装時の注意点

* 数式レンダリング処理は `LaTeXVeiw.swift` に閉じ込める
* 画面側では `LaTeXView` / `LaTeXTextView` を呼ぶだけにする
* KaTeX の CDN 読み込みには戻さない
* JSON では必ずバックスラッシュを `\\` にする
* 説明文内の数式は `$...$` を基本にする
* ボタン内の `LaTeXView` には `.allowsHitTesting(false)` を付ける
* 新しい数式コマンドを使う場合は、KaTeX が対応しているか確認する
* 実機では Bundle のファイル名大小文字の違いが問題になりやすいので、`katex`, `katex.min.css`, `katex.min.js`, `fonts` の名前を変えない

---

## 16. 最小実装例

新しい画面で単独の数式を表示したい場合は、以下だけで表示できます。

```swift
struct SampleFormulaView: View {
    var body: some View {
        LaTeXView(latex: #"x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}"#)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color(uiColor: .systemBackground))
    }
}
```

説明文に数式を混ぜたい場合は以下です。

```swift
struct SampleExplanationView: View {
    var body: some View {
        LaTeXTextView(text: "解の公式は $x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$ です。")
            .padding()
    }
}
```

JSON に書く場合は以下です。

```json
{
  "explanation": "解の公式は $x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$ です。",
  "formula": "x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}",
  "choices": [
    "x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}",
    "x=\\frac{b\\pm\\sqrt{b^2-4ac}}{2a}",
    "x=\\frac{-b\\pm\\sqrt{b^2+4ac}}{2a}",
    "x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{a}"
  ],
  "correctIndex": 0
}
```

---

## 17. まとめ

FormulaPath の数式表示は、以下の責務分離で成り立っています。

* SwiftUI はレイアウトと画面構成を担当する
* `WKWebView` は KaTeX を動かすための実行環境になる
* KaTeX は LaTeX 文字列を HTML/CSS の美しい数式に変換する
* `LaTeXView` は単独の数式表示を担当する
* `LaTeXTextView` は説明文内のインライン数式を担当する
* JSON は問題データとして LaTeX 文字列を保持する

新しい数式表示を追加するときは、まず `LaTeXView` または `LaTeXTextView` のどちらを使うべきかを決め、数式データは JSON 側に `\\frac` のようなエスケープ済み LaTeX として書いてください。
