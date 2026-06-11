//
//  StageSelectionView.swift
//  formulapath
//

import SwiftUI

struct StageSelectionView: View {

    // 大元のHomeViewにあるナビゲーションスタックの通り道を引き継ぐ
    @Binding var navigationPath: NavigationPath

    // 親（HomeView）から、それぞれのファイルのデータマネージャーを受け取る（疎結合）
    @ObservedObject var dataManager: GameDataManager
    
    // 💡 画面ごとに「中学校」「高校」「大学」とタイトルを切り替えるために外から貰うよ！
    let navigationTitle: String

    var body: some View {
        ZStack {
            // 背景を薄いシステム背景色に
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                
                // 画面中央に縦に並ぶメニューリスト（スクロールできるようにScrollViewに包む）
                ScrollView {
                    VStack(spacing: 16) {
                        // 💡 渡されたデータマネージャー内の問題をループで回して動的にカードを作る！
                        ForEach(dataManager.menuProblems) { problemWithProgress in
                            // TitleやStatusの情報をしっかり抽出してUIに反映！
                            MenuCard(
                                title: problemWithProgress.problem.title, 
                                subtitle: "ステータス: \(problemWithProgress.status)", 
                                icon: "function"
                            ) {
                                // タップしたら、その問題データを引っ提げてゲーム画面へ遷移する
                                navigationPath.append(problemWithProgress.problem)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .navigationTitle(navigationTitle) // 💡 貰ったタイトルをここにセット！
        .navigationBarTitleDisplayMode(.inline)
    }
}

// （※ 下部の MenuCard や MenuCardButtonStyle のコードは前のまま一切消さずに残してね！）
