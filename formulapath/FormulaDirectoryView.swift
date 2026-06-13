//
//  FormulaDirectoryView.swift
//  formulapath
//

import SwiftUI

struct FormulaDirectoryView: View {

    // 大元のHomeViewにあるナビゲーションスタックの通り道を引き継ぐ
    @Binding var navigationPath: NavigationPath

    let directoryTitle: String

    // 💡 StageSelectionViewで管理されているGameDataManagerを参照し、進捗更新の単一データ源を保つ
    @ObservedObject var dataManager: GameDataManager

    private var directoryProblems: [ProblemWithProgress] {
        dataManager.menuProblems.filter { problemWithProgress in
            problemWithProgress.problem.directory == directoryTitle
        }
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
                        // 💡 選択されたディレクトリ内の問題をループで回して動的にカードを作る！
                        ForEach(directoryProblems) { problemWithProgress in
                            // TitleやStatusの情報をしっかり抽出してUIに反映！
                            MenuCard(
                                title: problemWithProgress.problem.title,
                                subtitle: "ステータス: \(problemWithProgress.status)",
                                icon: "function"
                            ) {
                                let targetProblem = problemWithProgress.problem
                                print("--- 📱 FormulaDirectoryView: カードがタップされました ---")
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
        .navigationTitle(directoryTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
