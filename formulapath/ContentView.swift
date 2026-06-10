//
//  ContentView.swift
//  formulapath
//
//  Created by Apple on 2026/06/09.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        FormulaPathHomeView()
        // 画面が表示された瞬間に処理を走らせる .onAppear という便利な機能
        .onAppear{
            // アプリ起動時（画面が表示された時）にJSONからデータを読み込む
            let loadedProblems = JSONManager.loadProblems()

            // ちゃんと読み込めたか、コンソールに表示して確認！
            if let firstProblem = loadedProblems.first {
                    print("--- MVPデータ読み込み成功！ ---")
                    print("タイトル: \(firstProblem.title)")
                    print("最初の数式: \(firstProblem.initialFormula)")
                    print("途中式の数: \(firstProblem.steps.count)ステップ")
                    
                    // 最初のステップの中身も見てみる
                    if let firstStep = firstProblem.steps.first {
                        print("ステップ1解説: \(firstStep.explanation)")
                        print("ステップ1数式: \(firstStep.formula)")
                    }

                    // 💡 ここからSQLiteのMVPテスト（読み込み・保存）を追加するよ！
                    print("\n--- ② SQLiteの進捗データ読み込み・保存テストスタート ---")
                    let dbManager = SQLiteManager()

                    // 1. まずは現在のステータスを読み込んでみる（初回はデータがないので初期値 "unlocked" が返るよ）
                    let initialStatus = dbManager.getStatus(for: firstProblem.id)
                    print("保存前のSQLite上のステータス: \(initialStatus)")

                    // 2. テストとして「cleared（クリア済）」という状態をSQLiteに保存してみる
                    dbManager.saveProgress(problemId: firstProblem.id, status: "cleared")

                    // 3. 保存した後に、もう一度SQLiteから読み込んで、本当に「cleared」に変わったか確認！
                    let savedStatus = dbManager.getStatus(for: firstProblem.id)
                    print("保存後のSQLite上のステータス: \(savedStatus)")
                    print("-------------------------------------------\n")

                } else {
                    print("問題データが読み込めませんでした。")
                }

        }
    }
}

#Preview {
    ContentView()
}
