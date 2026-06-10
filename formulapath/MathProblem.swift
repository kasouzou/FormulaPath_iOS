import Foundation

// 途中式の1ステップ分のデータ
struct DerivationStep: Codable {
    let stepNumber: Int
    let explanation: String
    let formula: String
}

// 問題全体のデータ
struct MathProblem: Codable {
    let id: String
    let title: String
    let initialFormula: String
    let steps: [DerivationStep]
}

// JSON（問題データ）とSQLite（ユーザー状態）を合体させたデータ構造
// SwiftUIのListなどでそのままループを回せるように、Identifiableに適合させておくよ！
struct ProblemWithProgress: Identifiable {
    // 問題ID（"quad_01" など）をそのままこのデータの識別IDとして使う
    var id: String { problem.id }
    
    let problem: MathProblem // JSONから読んだ問題の中身
    let status: String       // SQLiteから読んだユーザーの進捗状態
}
