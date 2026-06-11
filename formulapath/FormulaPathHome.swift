//
//  FormulaPathHomeView.swift
//  formulapath
//

import SwiftUI


// 画面遷移先を綺麗に管理するためのEnum（カプセル化・疎結合の意識）
enum FormulaPathDestination: Hashable {
    case juniorHigh
    case high
    case university
}

// 💡 ゲーム画面にはMathProblemだけでなく、進捗更新を担当するGameDataManagerも一緒に渡す
struct FormulaPathGameRoute: Hashable {
    let problem: MathProblem
    let dataManager: GameDataManager

    static func == (lhs: FormulaPathGameRoute, rhs: FormulaPathGameRoute) -> Bool {
        lhs.problem == rhs.problem && lhs.dataManager === rhs.dataManager
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(problem)
        hasher.combine(ObjectIdentifier(dataManager))
    }
}

struct FormulaPathHomeView: View {
    // 画面のスタック状態を管理するパス
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack (path: $navigationPath){
            ZStack {
                // 背景を薄いシステム背景色に
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // アプリ名（ほんのりピンク〜パープルのグラデーションでアクセント）
                    VStack(spacing: 8) {
                        Text("FormulaPath")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.init(red: 1.0, green: 0.4, blue: 0.6), .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 中央揃えで2行のテキストを表示
                        VStack(alignment: .center, spacing: 4) {
                            Text("数式導出パズルゲーム")
                            Text("数式の成り立ちを理解する")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    }

                    // 画面中央に縦に並ぶメニューリスト
                    VStack(spacing: 16) {
                        MenuCard(title: "中学", subtitle: "Junior High School", icon: "square.and.pencil") {
                            // TODO: 中学ステージ
                            navigationPath.append(FormulaPathDestination.juniorHigh)
                        }
                        
                        MenuCard(title: "高校", subtitle: "High School", icon: "function") {
                            // 高校ステージ
                            navigationPath.append(FormulaPathDestination.high)
                        }
                        
                        MenuCard(title: "大学", subtitle: "University", icon: "graduationcap") {
                            // 大学ステージ
                            navigationPath.append(FormulaPathDestination.university)
                        }
                        
                        MenuCard(title: "ランダム", subtitle: "Random", icon: "infinity") {
                            // TODO: ランダムステージ (今後追加予定)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }


            // 遷移先のViewをここで一括管理（ホームのロジックと遷移先を分離）
            .navigationDestination(for: FormulaPathDestination.self) { destination in
                switch destination {
                case .juniorHigh:
                    StageSelectionView(
                        navigationPath: $navigationPath,
                        fileName: "junior_high_quizzes", // ➔ 中学用JSONの名前を渡す
                        navigationTitle: "中学校 公式一覧"
                    )
                case .high:
                    StageSelectionView(
                        navigationPath: $navigationPath,
                        fileName: "high_school_quizzes", // ➔ 高校用JSON (今後追加)
                        navigationTitle: "高校 公式一覧"
                    )
                case .university:
                    StageSelectionView(
                        navigationPath: $navigationPath,
                        fileName: "university_quizzes",  // ➔ 大学用JSON (今後追加)                      
                        navigationTitle: "大学 公式一覧"
                    )            
                }
            }
            // 💡 【ココを追加！】MathProblemデータそのものが飛んできた時のゲーム画面へのルートを定義！
            // 💡 GameDataManagerも一緒に運び、クリア時の進捗更新をStageSelectionView側の単一データ源へ戻す
            .navigationDestination(for: FormulaPathGameRoute.self) { route in
                // 選択された問題を渡して、ゲーム本編画面を起動する
                GamePlayView(
                    navigationPath: $navigationPath,
                    problem: route.problem,
                    dataManager: route.dataManager
                )
            }
        }
    }
}


#Preview {
    FormulaPathHomeView()
}
