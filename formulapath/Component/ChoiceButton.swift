// 選択肢ボタンのコンポーネント（再利用性とカプセル化を意識）

import SwiftUI

struct ChoiceButton: View {
    let text: String
    var isFullWidth: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            // ボタンの中の数式も綺麗にレンダリングできるように、TextからLaTeXViewに変更したよ！
            // ※ .fontや.fontWeightなどのテキスト専用モディファイアは、LaTeXView内部のレンダラー側で制御するためここで一度外してスッキリさせているよ
            LaTeXView(latex: text)
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
        }
        .buttonStyle(ChoiceButtonStyle())
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
