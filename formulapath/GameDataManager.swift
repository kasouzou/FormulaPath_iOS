import SwiftUI 
import Combine

// 💡 データの読み込みと合体ロジックをカプセル化する管理職人クラス
// 画面側（UI）はこのクラスだけを呼べばよくなるので、お互いの存在に依存しない「疎結合」な設計になるよ！
class GameDataManager: ObservableObject {
    // 💡 合体済みの問題リスト（この値が更新されると、SwiftUIの画面が自動でピキーンと再描画されるよ！）
    @Published var menuProblems: [ProblemWithProgress] = []
    
    // SQLiteを操作するマネージャーを内部に隠し持っておく（カプセル化）
    private let sqliteManager = SQLiteManager()

    // 💡 【ここを追加！】今自分が担当しているファイル名をクラスの中に記憶しておく変数（カプセル化）
    private let fileName: String
    
    init(fileName: String) {
        // 💡 渡されたファイル名を、上の変数にしっかり記憶させておく！
        self.fileName = fileName

        // クラスが作られた瞬間に、自動でデータを合体させて準備する
        loadAndMergeData(fileName: fileName)
    }
    
    // 💡 【中心ロジック】JSONとSQLiteのデータをIDで合体させる関数
    func loadAndMergeData(fileName: String) {
        // 1. JSONManagerを使って、引数に渡されたJSONファイル内の全問題のリストを取得する
        let loadedProblems = JSONManager.loadProblems(fileName: fileName)
        
        // 2. 高階関数 map を使って、全問題をループで回しながらIDを基準にSQLiteのステータスと合体させる！
        self.menuProblems = loadedProblems.map { problem in
            // 問題のID（例: "quad"）を使って、SQLiteから現在の状態（"unlocked" や "cleared"）を取得
            let currentStatus = sqliteManager.getStatus(for: problem.id)
            let isPinned = sqliteManager.isPinned(for: problem.id)
            
            // 1つのパッケージにして配列に格納する
            return ProblemWithProgress(problem: problem, status: currentStatus, isPinned: isPinned)
        }
        
        print("--- 💡 GameDataManager: データの合体が完了しました（総数: \(menuProblems.count)件） ---")
        // 💡 【修正ポイント】for-in文を使って、配列のすべてのデータをループで回して把握するよ！
                for item in menuProblems {
                    print("[確認] ID: \(item.id) | タイトル: \(item.problem.title) | 進捗状態: \(item.status)")
                }
    }
    
    // 💡 今後ゲームをクリアした時に、進捗を保存して合体データを最新に更新するための関数
    func updateProgress(problemId: String, newStatus: String) {
        sqliteManager.saveProgress(problemId: problemId, status: newStatus)
        // 保存が終わったら、もう一度合体処理を走らせて、保持しているデータを最新状態にする
        loadAndMergeData(fileName: self.fileName)
    }

    // 💡 一覧画面のピン留め状態もGameDataManager経由で更新して、単一データ源を守るよ！
    func updatePinned(problemId: String, isPinned: Bool) {
        sqliteManager.savePinned(problemId: problemId, isPinned: isPinned)
        // 保存が終わったら、もう一度合体処理を走らせて、保持しているデータを最新状態にする
        loadAndMergeData(fileName: self.fileName)
    }

    // 💡 UI側は現在の状態を渡すだけで、保存処理の詳細はこのクラスに隠しておく
    func togglePinned(problemId: String) {
        guard let targetProblem = menuProblems.first(where: { $0.id == problemId }) else { return }
        updatePinned(problemId: problemId, isPinned: !targetProblem.isPinned)
    }
}
