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

    private var directorySummaries: [FormulaDirectorySummary] {
        var summaries: [FormulaDirectorySummary] = []

        for problemWithProgress in dataManager.menuProblems {
            let directoryTitle = problemWithProgress.problem.directory

            if let index = summaries.firstIndex(where: { $0.title == directoryTitle }) {
                summaries[index].problemCount += 1
            } else {
                summaries.append(
                    FormulaDirectorySummary(
                        title: directoryTitle,
                        problemCount: 1
                    )
                )
            }
        }

        return summaries
    }

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
                        // 💡 渡されたデータマネージャー内の問題をディレクトリごとにまとめて、動的にカードを作る！
                        ForEach(directorySummaries) { directory in
                            // Titleや問題数の情報をしっかり抽出してUIに反映！
                            MenuCard(
                                title: directory.title,
                                subtitle: "問題数: \(directory.problemCount)件",
                                icon: "folder"
                            ) {
                                print("--- 📱 StageSelectionView: ディレクトリカードがタップされました ---")
                                print("[遷移データ] ディレクトリ名: \(directory.title)")
                                print("[遷移データ] 問題数: \(directory.problemCount)件")

                                // タップしたら、そのディレクトリ名を引っ提げて問題一覧画面へ遷移する
                                navigationPath.append(
                                    FormulaDirectoryRoute(
                                        directoryTitle: directory.title,
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

private struct FormulaDirectorySummary: Identifiable {
    var id: String { title }

    let title: String
    var problemCount: Int
}
