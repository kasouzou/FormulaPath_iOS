//
//  FormulaDirectoryView.swift
//  formulapath
//

import SwiftUI

struct FormulaDirectoryView: View {

    // 大元のHomeViewにあるナビゲーションスタックの通り道を引き継ぐ
    @Binding var navigationPath: NavigationPath

    let directoryTitle: String

    // 💡 StageSelectionViewで管理されているGameDataManagerを参照し、進捗更新の単一データ源を保つ
    @ObservedObject var dataManager: GameDataManager

    private var directoryProblems: [ProblemWithProgress] {
        dataManager.menuProblems
            .filter { problemWithProgress in
                problemWithProgress.problem.directory == directoryTitle
            }
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isPinned != rhs.element.isPinned {
                    return lhs.element.isPinned && !rhs.element.isPinned
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    var body: some View {
        ZStack {
            // 背景を薄いシステム背景色に
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 画面中央に縦に並ぶメニューリスト（スクロールできるようにScrollViewに包む）
                ScrollView {
                    VStack(spacing: 16) {
                        // 💡 選択されたディレクトリ内の問題をループで回して動的にカードを作る！
                        ForEach(directoryProblems) { problemWithProgress in
                            // TitleやStatusの情報をしっかり抽出してUIに反映！
                            PinnedProblemCard(
                                title: problemWithProgress.problem.title,
                                subtitle: "ステータス: \(problemWithProgress.status)",
                                icon: "function",
                                isPinned: problemWithProgress.isPinned,
                                pinAction: {
                                    dataManager.togglePinned(problemId: problemWithProgress.id)
                                }
                            ) {
                                let targetProblem = problemWithProgress.problem
                                print("--- 📱 FormulaDirectoryView: カードがタップされました ---")
                                print("[problemWithProgress.problemの中身]: \(targetProblem)")
                                print("[遷移データ] 問題ID: \(targetProblem.id)")
                                print("[遷移データ] タイトル: \(targetProblem.title)")
                                print("[遷移データ] 初期数式: \(targetProblem.initialFormula)")
                                print("[遷移データ] 総ステップ数: \(targetProblem.steps.count)件")

                                // タップしたら、その問題データを引っ提げてゲーム画面へ遷移する
                                navigationPath.append(
                                    FormulaPathGameRoute(
                                        problem: problemWithProgress.problem,
                                        dataManager: dataManager
                                    )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .navigationTitle(directoryTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PinnedProblemCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isPinned: Bool
    let pinAction: () -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: action) {
                HStack(spacing: 16) {
                    // アイコン部分（ほんのりピンクのバックグラウンド）
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.pink)
                        .frame(width: 48, height: 48)
                        .background(Color.pink.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color(uiColor: .label))
                            .lineLimit(2)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PinnedProblemCardButtonStyle())

            Button(action: pinAction) {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isPinned ? .pink : .secondary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isPinned ? Color.pink.opacity(0.12) : Color(uiColor: .secondarySystemGroupedBackground))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPinned ? "ピン留めを解除" : "ピン留め")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isPinned ? Color.pink.opacity(0.22) : Color.clear, lineWidth: 1)
        )
    }
}

// タップ時のフィードバック用アニメーションスタイル
private struct PinnedProblemCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
