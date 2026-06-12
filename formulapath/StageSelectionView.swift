//
//  StageSelectionView.swift
//  formulapath
//

import SwiftUI

struct StageSelectionView: View {

    // 大元のHomeViewにあるナビゲーションスタックの通り道を引き継ぐ
    @Binding var navigationPath: NavigationPath

    // 💡 【安全な設計に変更】親からはファイル名を受け取り、内部でStateObjectとして安全にライフサイクルを管理するよ（疎結合）
    @StateObject private var dataManager: GameDataManager
    
    // 💡 画面ごとに「中学校」「高校」「大学」とタイトルを切り替えるために外から貰うよ！
    let navigationTitle: String

    init(navigationPath: Binding<NavigationPath>, fileName: String, navigationTitle: String) {
        self._navigationPath = navigationPath
        self.navigationTitle = navigationTitle
        // 💡 渡されたfileNameを使って、データマネージャーを安全に初期化するよ！
        self._dataManager = StateObject(wrappedValue: GameDataManager(fileName: fileName))
    }

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
                                let targetProblem = problemWithProgress.problem
                                print("--- 📱 StageSelectionView: カードがタップされました ---")
                                print("[problemWithProgress.problemの中身]: \(targetProblem)")
                                print("[遷移データ] 問題ID: \(targetProblem.id)")
                                print("[遷移データ] タイトル: \(targetProblem.title)")
                                print("[遷移データ] 初期数式: \(targetProblem.initialFormula)")
                                print("[遷移データ] 総ステップ数: \(targetProblem.steps.count)件")

                                // タップしたら、その問題データを引っ提げてゲーム画面へ遷移する
                                navigationPath.append(
                                    FormulaPathGameRoute(
                                        problem: problemWithProgress.problem,
                                        dataManager: dataManager
                                    )
                                )
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
