import SwiftUI // 💡 ここを import Foundation から import SwiftUI に変更したよ！
import Combine

// 💡 データの読み込みと合体ロジックをカプセル化する管理職人クラス
// 画面側（UI）はこのクラスだけを呼べばよくなるので、お互いの存在に依存しない「疎結合」な設計になるよ！
class GameDataManager: ObservableObject {
    // 💡 合体済みの問題リスト（この値が更新されると、SwiftUIの画面が自動でピキーンと再描画されるよ！）
    @Published var menuProblems: [ProblemWithProgress] = []
    
    // SQLiteを操作するマネージャーを内部に隠し持っておく（カプセル化）
    private let sqliteManager = SQLiteManager()
    
    init() {
        // クラスが作られた瞬間に、自動でデータを合体させて準備する
        loadAndMergeData()
    }
    
    // 💡 【中心ロジック】JSONとSQLiteのデータをIDで合体させる関数
    func loadAndMergeData() {
        // 1. JSONManagerを使って、全問題のリストをJSONから取得する
        let loadedProblems = JSONManager.loadProblems()
        
        // 2. 高階関数 map を使って、全問題をループで回しながらIDを基準にSQLiteのステータスと合体させる！
        self.menuProblems = loadedProblems.map { problem in
            // この問題のID（例: "quad_01"）を使って、SQLiteから現在の状態（"unlocked" や "cleared"）を取得
            let currentStatus = sqliteManager.getStatus(for: problem.id)
            
            // 1つのパッケージにして配列に格納する
            return ProblemWithProgress(problem: problem, status: currentStatus)
        }
        
        print("--- 💡 GameDataManager: データの合体が完了しました（総数: \(menuProblems.count)件） ---")
        if let first = menuProblems.first {
            print("    ➔ [確認] ID: \(first.id) | タイトル: \(first.problem.title) | 進捗: \(first.status)")
        }
    }
    
    // 💡 今後ゲームをクリアした時に、進捗を保存して合体データを最新に更新するための関数
    func updateProgress(problemId: String, newStatus: String) {
        sqliteManager.saveProgress(problemId: problemId, status: newStatus)
        // 保存が終わったら、もう一度合体処理を走らせて、保持しているデータを最新状態にする
        loadAndMergeData()
    }
}
