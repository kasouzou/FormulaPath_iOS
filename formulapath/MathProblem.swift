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
