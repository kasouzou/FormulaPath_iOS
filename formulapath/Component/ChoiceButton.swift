// 選択肢ボタンのコンポーネント（再利用性とカプセル化を意識）

import SwiftUI

struct ChoiceButton: View {
    let text: String
    var isFullWidth: Bool = false
    let action: () -> Void
    
    // 💡 長すぎる数式用のシート表示フラグをカプセル化して管理
    @State private var isShowingDetail = false
    
    // 💡 【イタチごっこを終わらせる判定基準】
    // 表示されるボタンのレイアウト幅（1列か2列か）と、数式の特徴を掛け合わせてスマートに判定するよ！
    private var isTooLong: Bool {
        if isFullWidth {
            // 💡 1列（全幅）の時は画面いっぱいに広がるので、28文字以上の長文や、分数・ルートなど高さが出て潰れやすい複雑な構造を目安にする
            return text.count > 28 || text.contains("\\frac") || text.contains("\\sqrt")
        } else {
            // 💡 2列（グリッド）の時はボタンの横幅がかなり狭い（iPhoneだと150pt前後）ので、
            // 12文字を超えるか、イコール「=」や矢印「\to」が入って式が展開されている場合は即シート行きにする！
            return text.count > 12 || text.contains("=") || text.contains("\\to") || text.contains("\\rightarrow")
        }
    }
    
    var body: some View {
        Button(action: {
            if isTooLong {
                // 💡 長い数式の場合は、その場で回答せずまずシートを開く
                isShowingDetail = true
            } else {
                action()
            }
        }) {
            if isTooLong {
                // 💡 長い場合は「選択肢を見る」というテキストとアイコンでスマートにレイアウト
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.pink)
                    Text("選択肢を見る")
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundStyle(Color(uiColor: .label))
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: isFullWidth ? 68 : 88) // 2列の時は押しやすいように少し高めに設定
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.pink.opacity(0.12), lineWidth: 1)
                )
                .contentShape(Rectangle()) // 💡 【お守り】透明な背景部分をタップしても確実にButtonが反応するようにする設定
            } else {
                // ボタンの中の数式も綺麗にレンダリングできるように、TextからLaTeXViewに変更したよ！
                // ※ .fontや.fontWeightなどのテキスト専用モディファイアは、LaTeXView内部のレンダラー側で制御するためここで一度外してスッキリさせているよ
                LaTeXView(latex: text)
                    .allowsHitTesting(false) // 💡 【超重要】これを入れることで、中のWebViewがタップを横取りするのを防ぎます！
                    .foregroundStyle(Color(uiColor: .label))
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: isFullWidth ? 68 : 88) // 2列の時は押しやすいように少し高めに設定
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 10, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.pink.opacity(0.12), lineWidth: 1)
                    )
                    .contentShape(Rectangle()) // 💡 【お守り】透明な背景部分をタップしても確実にButtonが反応するようにする設定
            }
        }
        .buttonStyle(ChoiceButtonStyle())
        // 💡 大きな数式をゆったり見せるためのハーフモーダル（ボトムシート）
        .sheet(isPresented: $isShowingDetail) {
            VStack(spacing: 24) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 16)
                
                Text("選択肢の詳細")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 💡 ボトムシートの中で、はみ出しを気にせず広々と数式を見せるゾーン
                LaTeXView(latex: text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    isShowingDetail = false
                    // 💡 シートを閉じながら、本来親から渡されている回答送信アクションを実行！
                    action()
                }) {
                    Text("この選択肢を選択する")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.pink)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .presentationDetents([.medium]) // 💡 iOS 16+ の機能で絶妙なハーフサイズに固定するよ
            .presentationDragIndicator(.hidden)
        }
    }
}

// クイズ選択肢専用のぷにっとした押し心地のボタンアニメーション
private struct ChoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
