//
//  FormulaPathHomeView.swift
//  formulapath
//

import SwiftUI


// 画面遷移先を綺麗に管理するためのEnum（カプセル化・疎結合の意識）
enum FormulaPathDestination: Hashable {
    case juniorHigh
    case High
}

struct FormulaPathHomeView: View {
    // 画面のスタック状態を管理するパス
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack (path: $navigationPath){
            ZStack {
                // 背景を薄いシステム背景色に
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // アプリ名（ほんのりピンク〜パープルのグラデーションでアクセント）
                    VStack(spacing: 8) {
                        Text("FormulaPath")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.init(red: 1.0, green: 0.4, blue: 0.6), .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 中央揃えで2行のテキストを表示
                        VStack(alignment: .center, spacing: 4) {
                            Text("数式導出パズルゲーム")
                            Text("数式の成り立ちを理解する")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    }

                    // 画面中央に縦に並ぶメニューリスト
                    VStack(spacing: 16) {
                        MenuCard(title: "中学", subtitle: "Junior High School", icon: "square.and.pencil") {
                            // TODO: 中学ステージ選択への遷移ロジック
                            navigationPath.append(FormulaPathDestination.juniorHigh)
                        }
                        
                        MenuCard(title: "高校", subtitle: "High School", icon: "function") {
                            // TODO: 高校ステージ選択への遷移ロジック
                            navigationPath.append(FormulaPathDestination.High)
                        }
                        
                        MenuCard(title: "大学", subtitle: "University", icon: "graduationcap") {
                            // TODO: 大学ステージ選択への遷移ロジック
                        }
                        
                        MenuCard(title: "ランダム", subtitle: "Random", icon: "infinity") {
                            // TODO:  ランダムステージ選択への遷移ロジック
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }


            // 遷移先のViewをここで一括管理（ホームのロジックと遷移先を分離）
            .navigationDestination(for: FormulaPathDestination.self) { destination in
                switch destination {
                case .juniorHigh:
                    JuniorHighStageSelectionView(navigationPath: $navigationPath)
                case .High:
                    HighStageSelectionView()
                }
            }
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
    FormulaPathHomeView()
}
