import Foundation

// 途中式の1ステップ分のデータ
// 💡 NavigationPathで使えるように、Hashableを追加するよ！
struct DerivationStep: Codable, Hashable {
    let stepNumber: Int
    let explanation: String
    let diagramSVG: String?
    let formula: String
    let choices: [String]      // 💡 追加：4択の選択肢の文字列配列
    let correctIndex: Int   // 💡 追加：正解のインデックス（0〜3）
}

// 問題全体のデータ
// 💡 ここにも Hashable を追加してあげることで、NavigationPathに安全にappendできるようになるよ！
struct MathProblem: Codable, Hashable {
    let id: String
    let title: String
    let directory: String
    let initialFormula: String
    let diagramSVG: String?
    let steps: [DerivationStep]
}

// JSON（問題データ）とSQLite（ユーザー状態）を合体させたデータ構造
// SwiftUIのListなどでそのままループを回せるように、Identifiableに適合させておくよ！
struct ProblemWithProgress: Identifiable {
    // 問題ID（"quad_01" など）をそのままこのデータの識別IDとして使う
    var id: String { problem.id }
    
    let problem: MathProblem // JSONから読んだ問題の中身
    let status: String       // SQLiteから読んだユーザーの進捗状態
    let isPinned: Bool       // SQLiteから読んだピン留め状態
}
