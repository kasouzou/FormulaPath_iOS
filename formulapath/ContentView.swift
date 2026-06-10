//
//  ContentView.swift
//  formulapath
//
//  Created by Apple on 2026/06/09.
//


import SwiftUI

struct ContentView: View {
    // 💡 アプリ全体で使うデータ管理職人をここで1大元としてインスタンス化するよ！
    @StateObject private var dataManager = GameDataManager()

    var body: some View {
        FormulaPathHomeView()
        
        // 💡 FormulaPathHomeViewとそれの遷移先ページのどこからでもこのデータにアクセスできるように環境オブジェクトとして注入（疎結合の意識！）
        .environmentObject(dataManager)
    }
}

#Preview {
    ContentView()
}
