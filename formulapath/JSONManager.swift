import Foundation

class JSONManager {
    private static let isVerboseLoggingEnabled = false

    // quizzes.jsonを読み込んで、[MathProblem]（配列）にして返す関数
    static func loadProblems(fileName: String) -> [MathProblem] {
        // 1. アプリ内（Bundle）から JSONファイルのの住所（URL）を探す
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("エラー: JSON ファイルがアプリ内に見つかりません。Target Membershipを確認してね。")
            return []
        }
        
        if isVerboseLoggingEnabled {
            // 【②のプリント】見つかったファイルの実際の住所（URL）を表示！
            print("ーーー ② urlの中身 ーーー")
            print(url)
            print("------------------------\n")
        }
        
        do {
            // 2. ファイルのデータを丸ごとバイナリデータ（Data型）として読み込む
            let data = try Data(contentsOf: url)
            
            if isVerboseLoggingEnabled {
                // 【④のプリント】読み込んだ直後の生データ（バイト数）を表示！
                print("ーーー ④ dataの中身 ーーー")
                print(data)
                print("バイト数: \(data.count) bytes")
                print("------------------------\n")
            }
            
            // 3. JSONDecoderを使って、JSONデータをSwiftの構造体配列に翻訳する
            let decoder = JSONDecoder()
            let problems = try decoder.decode([MathProblem].self, from: data)
            
            if isVerboseLoggingEnabled {
                // 【⑤のプリント】翻訳が完了して、Swiftの構造体になった中身を表示！
                print("ーーー ⑤ problemsの中身 ーーー")
                print(problems)
                dump(problems)
                print("------------------------\n")
            }
            
            return problems
        } catch {
            print("エラー: JSONの読み込み、または解析に失敗しました: \(error)")
            
            // 【③のプリント（catch用）】失敗したときは空っぽの箱を返すよ
            print("ーーー ③（エラー時）戻り値の中身 ーーー")
            print([])
            print("------------------------\n")
            return []
        }
    }
}
