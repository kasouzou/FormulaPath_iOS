//
//  JuniorHighStageSelectionView.swift
//  formulapath
//

import SwiftUI

// 画面遷移先を綺麗に管理するためのEnum（カプセル化・疎結合の意識）
enum JuniorHighStageSelectionDestination: Hashable {
    case DOTQF
    case other
}

struct JuniorHighStageSelectionView: View {

    // 💡【ココを追加！】大元のHomeViewにあるナビゲーションスタックの通り道を引き継ぐよ！
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            // 背景を薄いシステム背景色に
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                // 画面中央に縦に並ぶメニューリスト
                VStack(spacing: 16) {
                    MenuCard(title: "交換法則・結合法則・分配法則", subtitle: "Junior High School", icon: "square.and.pencil") {
                        // TODO: 中学ステージ選択への遷移ロジック
                    }
                    
                    MenuCard(title: "等式の性質", subtitle: "High School", icon: "function") {
                        // TODO: 高校ステージ選択への遷移ロジック
                    }
                    
                    MenuCard(title: "指数法則", subtitle: "University", icon: "graduationcap") {
                        // TODO: 大学ステージ選択への遷移ロジック
                    }
                    
                    MenuCard(title: "２次方程式の解の公式", subtitle: "Random", icon: "infinity") {
                        // TODO:  2次方程式の解の公式への遷移ロジック
                        navigationPath.append(JuniorHighStageSelectionDestination.DOTQF)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }

            // 遷移先のViewをここで一括管理
            .navigationDestination(for: JuniorHighStageSelectionDestination.self) { destination in
                switch destination {
                case .DOTQF:
                    DOTQFView()
                case .other:
                    HighStageSelectionView()
                }
            }
            // ナビゲーションバーのタイトル設定は大元のスタックに引き継がれるよ
            .navigationTitle("中学校の数学")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 元のコードの美しいカードデザインのテイストを引き継いだメニューコンポーネント
private struct MenuCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // アイコン部分（ほんのりピンクのバックグラウンド）
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.pink)
                    .frame(width: 48, height: 48)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color(uiColor: .label))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 12, y: 6)
            )
        }
        .buttonStyle(MenuCardButtonStyle())
    }
}

// タップ時のフィードバック用アニメーションスタイル
private struct MenuCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    // プレビュー単体で動かす時は、擬似的にスタックで囲ってあげると遷移の動きが確認できるよ！
    NavigationStack {
        // 💡 ここに navigationPath: .constant(NavigationPath()) を追加するよ！
        JuniorHighStageSelectionView(navigationPath: .constant(NavigationPath()))
    }
}

