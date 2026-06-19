import SwiftUI
import Combine

// MARK: - ViewModel (パズルの状態管理とSQLite連動)
final class GamePlayViewModel: ObservableObject {
    let problem: MathProblem

    // 💡 【安全な設計に変更】親からはファイル名を受け取り、内部でStateObjectとして安全にライフサイクルを管理するよ（疎結合）
    // GamePlayViewModelはSQLiteを直接触らず、StageSelectionViewで管理されているGameDataManagerへ進捗更新だけを依頼する
    private let dataManager: GameDataManager

    @Published private(set) var currentStepIndex: Int = 0
    @Published var selectedChoiceIndex: Int?
    @Published private(set) var isCleared: Bool = false
    @Published var showWrongAnswerEffect: Bool = false
    @Published private(set) var currentShuffledChoices: [String] = []

    private var currentCorrectChoiceIndex: Int?

    var currentStepNumber: Int {
        min(currentStepIndex + 1, max(problem.steps.count, 1))
    }

    // 現在解いているステップのデータ
    var currentStep: DerivationStep? {
        guard problem.steps.indices.contains(currentStepIndex) else { return nil }
        return problem.steps[currentStepIndex]
    }

    // 💡 現在のボードに表示すべき数式を動的に返す
    // Step 1 のときは初期数式(initialFormula)を表示し、正解するごとに前のステップの数式に更新されていくよ！
    var currentEquation: String {
        if currentStepIndex == 0 {
            return problem.initialFormula
        } else {
            return problem.steps[currentStepIndex - 1].formula
        }
    }

    var shouldShowCurrentEquation: Bool {
        !currentEquation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 💡 ステップ側の指定を優先し、図形を隠したい計算フェーズでは明示的に非表示にする
    var currentDiagramSVG: String? {
        guard let currentStep else { return nil }

        if currentStep.diagramDisplayMode == .hidden {
            return nil
        }

        return currentStep.diagramSVG ?? problem.diagramSVG
    }

    init(problem: MathProblem, dataManager: GameDataManager) {
        self.problem = problem
        self.dataManager = dataManager
        shuffleChoicesForCurrentStep()
    }

    deinit {
        print("--- GamePlayViewModel deinit: \(problem.id) ---")
    }

    @discardableResult
    func submitAnswer(selectedIndex: Int) -> Bool {
        // 💡 ViewModel側で選択肢のインデックスを受け取ったことを出力
        print("--- [ViewModel] submitAnswer called with index: \(selectedIndex) ---")
        
        guard !isCleared, let currentStep else { return false }
        selectedChoiceIndex = selectedIndex

        guard currentShuffledChoices.indices.contains(selectedIndex),
              let currentCorrectChoiceIndex,
              currentStep.choices.indices.contains(currentStep.correctIndex)
        else {
            triggerWrongAnswerEffect()
            return false
        }

        if selectedIndex == currentCorrectChoiceIndex {
            // 🎉 正解：次のステップへ進むか、全クリア判定
            return advanceToNextStepOrClear()
        } else {
            // ❌ 不正解：エラーハンドリング（画面を赤く光らせたりシェイクする演出用フラグ）
            triggerWrongAnswerEffect()
            return false
        }
    }

    private func advanceToNextStepOrClear() -> Bool {
        if currentStepIndex + 1 < problem.steps.count {
            withAnimation(.easeInOut) {
                currentStepIndex += 1
                selectedChoiceIndex = nil
                shuffleChoicesForCurrentStep()
            }
            return false
        } else {
            // SQLiteに進捗を安全に保存（カプセル化）
            dataManager.updateProgress(problemId: problem.id, newStatus: "cleared")
            withAnimation(.spring()) {
                isCleared = true
            }
            return true
        }
    }

    private func triggerWrongAnswerEffect() {
        withAnimation(.default) {
            showWrongAnswerEffect = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showWrongAnswerEffect = false
        }
    }

    private func shuffleChoicesForCurrentStep() {
        guard let currentStep,
              currentStep.choices.indices.contains(currentStep.correctIndex)
        else {
            currentShuffledChoices = []
            currentCorrectChoiceIndex = nil
            return
        }

        var shuffledChoices = Array(currentStep.choices.enumerated()).shuffled()

        if shuffledChoices.count > 1,
           let displayedCorrectIndex = shuffledChoices.firstIndex(where: { $0.offset == currentStep.correctIndex }),
           displayedCorrectIndex == currentStep.correctIndex,
           let swapIndex = shuffledChoices.indices.first(where: { $0 != displayedCorrectIndex }) {
            shuffledChoices.swapAt(displayedCorrectIndex, swapIndex)
        }

        currentShuffledChoices = shuffledChoices.map(\.element)
        currentCorrectChoiceIndex = shuffledChoices.firstIndex { $0.offset == currentStep.correctIndex }
    }
}

// MARK: - View (ユーザーが提示してくれた美しいデザインベース)
struct GamePlayView: View {
    // 大元のHomeViewにあるナビゲーションスタックの通り道を引き継ぐ
    @Binding private var navigationPath: NavigationPath
    @StateObject private var viewModel: GamePlayViewModel

    init(navigationPath: Binding<NavigationPath>, problem: MathProblem, dataManager: GameDataManager) {
        self._navigationPath = navigationPath
        self._viewModel = StateObject(
            wrappedValue: GamePlayViewModel(
                problem: problem,
                dataManager: dataManager
            )
        )
    }

    var body: some View {
        ZStack {
            // 背景を薄いシステム背景色に
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isCleared {
                clearedView
            } else if let step = viewModel.currentStep {
                playingView(step: step)
            } else {
                emptyStepsView
            }
        }
        .navigationTitle(viewModel.problem.title) // 💡 選択された問題のタイトルが自動で入るよ
        .navigationBarTitleDisplayMode(.inline)
    }

    // 🎉 全ステップクリア時の画面
    private var clearedView: some View {
        VStack(spacing: 24) {
            Text("STAGE CLEAR!")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(.green)

            Text("\(viewModel.problem.title) の導出に成功した！")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("公式一覧に戻る") {
                returnToStageSelection()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
        .padding()
    }

    // 🧩 パズルゲーム進行中の画面
    private func playingView(step: DerivationStep) -> some View {
        VStack(spacing: 24) {
            // ステップの進捗ヘッダー（例: Step 1 / 3）
            HStack {
                Text("Step \(viewModel.currentStepNumber) / \(viewModel.problem.steps.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // 【上部：数式表示ゾーン】
            VStack(spacing: 16) {
                // JSONから読み込んだヒントメッセージを動的に表示
                LaTeXTextView(text: step.explanation, isError: viewModel.showWrongAnswerEffect)
                    .padding(.horizontal, 8)
                    .animation(.default, value: viewModel.showWrongAnswerEffect)

                if let diagramSVG = viewModel.currentDiagramSVG {
                    // 💡 図形を使った説明があるステップだけ、JSON内のSVGを透明背景で表示するよ！
                    SVGDiagramView(svg: diagramSVG)
                        .padding(.horizontal, 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                if viewModel.shouldShowCurrentEquation {
                    equationBoard
                }
            }
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentStepIndex)

            Spacer(minLength: 12)

            // 【下部：3択または4択ゾーン】
            // 💡 切り出した共通パーツ ChoiceButton を使って美しくレイアウト！
            choiceButtons(for: viewModel.currentShuffledChoices)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }

    private var emptyStepsView: some View {
        VStack(spacing: 16) {
            Text("この問題にはステップがありません")
                .font(.headline)
                .foregroundStyle(.primary)

            Button("公式一覧に戻る") {
                returnToStageSelection()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private var equationBoard: some View {
        // メインの数式ボード（ほんのりピンクの枠線でFormulaPathらしさをプラス）
        // 独自にカプセル化したLaTeXViewに差し替えて、数式レンダラーをいつでも受け入れられるようにしたよ
        LaTeXView(latex: viewModel.currentEquation)
            .frame(maxWidth: .infinity)
            .frame(height: viewModel.currentDiagramSVG == nil ? 220 : 160)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 16, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                viewModel.showWrongAnswerEffect ? .red.opacity(0.6) : .pink.opacity(0.2),
                                viewModel.showWrongAnswerEffect ? .red.opacity(0.6) : .purple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: viewModel.showWrongAnswerEffect ? 2 : 1
                    )
            )
            .offset(x: viewModel.showWrongAnswerEffect ? -10 : 0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.2), value: viewModel.showWrongAnswerEffect)
    }

    @ViewBuilder
    private func choiceButtons(for choices: [String]) -> some View {
        VStack(spacing: 14) {
            if choices.count == 4 {
                // 4択の場合は綺麗な2x2グリッド
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        answerButton(choices: choices, index: 0)
                        answerButton(choices: choices, index: 1)
                    }
                    HStack(spacing: 14) {
                        answerButton(choices: choices, index: 2)
                        answerButton(choices: choices, index: 3)
                    }
                }
            } else if choices.count == 3 {
                // 3択の場合は上が2つ、下が1つの全幅ボタンにして画面のガタつきを防ぐ
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        answerButton(choices: choices, index: 0)
                        answerButton(choices: choices, index: 1)
                    }
                    answerButton(choices: choices, index: 2, isFullWidth: true)
                }
            } else {
                // 選択肢数が変わっても崩れないように、基本は縦積みで安全に表示する
                VStack(spacing: 14) {
                    ForEach(choices.indices, id: \.self) { index in
                        answerButton(choices: choices, index: index, isFullWidth: true)
                    }
                }
            }
        }
    }

    private func answerButton(choices: [String], index: Int, isFullWidth: Bool = false) -> some View {
        ChoiceButton(text: choices[index], isFullWidth: isFullWidth) {
            // 💡 ボタンがタップされたイベント、インデックス、テキストをコンソールに出力
            print("--- [View Tap] ChoiceButton tapped at index: \(index), text: \(choices[index]) ---")
            viewModel.submitAnswer(selectedIndex: index)
        }
        .disabled(viewModel.isCleared)
    }

    private func returnToStageSelection() {
        guard navigationPath.count > 0 else { return }
        navigationPath.removeLast()
    }
}
