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

    // 💡 親（HomeViewとか）からデータマネージャーを受け取るか、StateObjectとして持たせる
    @ObservedObject var dataManager: GameDataManager

    var body: some View {
        ZStack {
            // 背景を薄いシステム背景色に
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                // 画面中央に縦に並ぶメニューリスト
                VStack(spacing: 16) {
                    // 💡 JSONから読み込んだ問題をループで回して動的にカードを作る！
                    // （本当は「中学向け」の識別タグをJSONに持たせてフィルターするともっと良いよ！）
                    ForEach(dataManager.menuProblems) { problemWithProgress in
                        MenuCard(
                            title: problemWithProgress.problem.title, 
                            subtitle: "ステータス: \(problemWithProgress.status)", 
                            icon: "function"
                        ) {
                            // タップしたら、その問題データを引っ提げてゲーム画面（DOTQFViewなど）へ遷移する
                            navigationPath.append(problemWithProgress.problem)
                        }
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



