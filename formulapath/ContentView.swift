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
                } else {
                    print("問題データが読み込めませんでした。")
                }

        }
    }
}

#Preview {
    ContentView()
}
