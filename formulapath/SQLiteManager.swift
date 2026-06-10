import Foundation
import SQLite3


class SQLiteManager {
    // SQLiteのデータベースを指すポインタ（クラス外部には見せない）
    private var db: OpaquePointer?

    init() {
        openDatabase()
        createTable()
    }

    deinit {
        // インスタンスが破棄されるときに、安全にクローズする
        sqlite3_close(db)
    }

    // ① データベースファイルを開く（接続）
    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("MathGame.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("エラー: データベースを開けませんでした。")
        }
    }

    // ② ユーザー進捗を保存するテーブルを作成
    private func createTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS user_progress (
            problem_id TEXT PRIMARY KEY,
            status TEXT
        );
        """
        var statement: OpaquePointer?
        // sqlite3_prepare_v2 の各引数の役割：
        // 1. db              : 操作対象のデータベースハンドラ（接続情報）
        // 2. createTableSQL  : 実行したいSQL文の文字列
        // 3. -1              : SQL文の長さ（-1を指定すると、文字列の終端まで自動で読み込む）
        // 4. &statement      : 準備されたステートメント（コンパイル結果）の出力先ポインタ
        // 5. nil             : 未処理のSQL文の残りを指すポインタ（今回は1つだけなので不要）
        if sqlite3_prepare_v2(db, createTableSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("エラー: テーブル作成に失敗しました。")
            }
        }
        sqlite3_finalize(statement)
    }


    // ③ データの保存（UPSERT: すでにデータがあれば上書き、なければ挿入）
    func saveProgress(problemId: String, status: String) {
        let upsertSQL = """
        INSERT INTO user_progress (problem_id, status) VALUES (?, ?)
        ON CONFLICT(problem_id) DO UPDATE SET status = excluded.status;
        """
        
        var statement: OpaquePointer?
        
        // SQLの準備とエラーハンドリング
        guard sqlite3_prepare_v2(db, upsertSQL, -1, &statement, nil) == SQLITE_OK else {
            print("エラー: SQLの準備に失敗しました。")
            return
        }
        
        // SQL文の「？」に安全に値をバインド（セキュリティ対策・SQLインジェクション防止）
        sqlite3_bind_text(statement, 1, (problemId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (status as NSString).utf8String, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_DONE {
            print("成功: SQLiteに保存しました。 [ID: \(problemId), 状態: \(status)]")
        } else {
            print("エラー: データの保存に失敗しました。")
        }
        
        sqlite3_finalize(statement) // メモリ解放
    }

    // ④ データの読み込み
    func getStatus(for problemId: String) -> String {
        let querySQL = "SELECT status FROM user_progress WHERE problem_id = ?;"
        var statement: OpaquePointer?
        
        // 💡【ココがポイント！】
        // 最初にあらかじめ「データがなかったときの初期値」として "unlocked" を用意しておく
        var status = "unlocked" 
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (problemId as NSString).utf8String, -1, nil)
            
            // 🔍 SQLiteにデータを探してもらう SQLITE_ROWはデータ（行）が見つかったよ！という意味
            if sqlite3_step(statement) == SQLITE_ROW {
                // ➔【データがあった場合だけ】ココを通る！
                // データベースに保存されていた文字（"cleared" など）で、変数 status を上書きする
                if let cString = sqlite3_column_text(statement, 0) {
                    status = String(cString: cString)
                }
            }
            // ➔【データがない場合】は SQLITE_ROW にならないので、上の if 文の中身は完全に無視される！
        }
        sqlite3_finalize(statement)
        
        // 🎁 最終的な結果を返す
        return status 
}
}
