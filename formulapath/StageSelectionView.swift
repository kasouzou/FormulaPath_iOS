//
//  StageSelectionView.swift
//  formulapath
//

import SwiftUI

struct StageSelectionView: View {

    // 大元のHomeViewにあるナビゲーションスタックの通り道を引き継ぐ
    @Binding var navigationPath: NavigationPath

    // 💡 【安全な設計に変更】親からはファイル名を受け取り、内部でStateObjectとして安全にライフサイクルを管理するよ（疎結合）
    @StateObject private var dataManager: GameDataManager
    
    // 💡 画面ごとに「中学校」「高校」「大学」とタイトルを切り替えるために外から貰うよ！
    let navigationTitle: String

    private var directorySummaries: [FormulaDirectorySummary] {
        var summaries: [FormulaDirectorySummary] = []

        for problemWithProgress in dataManager.menuProblems {
            let directoryTitle = problemWithProgress.problem.directory

            if let index = summaries.firstIndex(where: { $0.title == directoryTitle }) {
                summaries[index].problemCount += 1
            } else {
                summaries.append(
                    FormulaDirectorySummary(
                        title: directoryTitle,
                        problemCount: 1,
                        isPinned: dataManager.isDirectoryPinned(directoryTitle: directoryTitle)
                    )
                )
            }
        }

        return summaries
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isPinned != rhs.element.isPinned {
                    return lhs.element.isPinned && !rhs.element.isPinned
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    init(navigationPath: Binding<NavigationPath>, fileName: String, navigationTitle: String) {
        self._navigationPath = navigationPath
        self.navigationTitle = navigationTitle
        // 💡 渡されたfileNameを使って、データマネージャーを安全に初期化するよ！
        self._dataManager = StateObject(wrappedValue: GameDataManager(fileName: fileName))
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
                        // 💡 渡されたデータマネージャー内の問題をディレクトリごとにまとめて、動的にカードを作る！
                        ForEach(directorySummaries) { directory in
                            // Titleや問題数の情報をしっかり抽出してUIに反映！
                            PinnedDirectoryCard(
                                title: directory.title,
                                subtitle: "問題数: \(directory.problemCount)件",
                                icon: "folder",
                                isPinned: directory.isPinned,
                                pinAction: {
                                    dataManager.toggleDirectoryPinned(directoryTitle: directory.title)
                                }
                            ) {
                                print("--- 📱 StageSelectionView: ディレクトリカードがタップされました ---")
                                print("[遷移データ] ディレクトリ名: \(directory.title)")
                                print("[遷移データ] 問題数: \(directory.problemCount)件")

                                // タップしたら、そのディレクトリ名を引っ提げて問題一覧画面へ遷移する
                                navigationPath.append(
                                    FormulaDirectoryRoute(
                                        directoryTitle: directory.title,
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
        .navigationTitle(navigationTitle) // 💡 貰ったタイトルをここにセット！
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FormulaDirectorySummary: Identifiable {
    var id: String { title }

    let title: String
    var problemCount: Int
    let isPinned: Bool
}

private struct PinnedDirectoryCard: View {
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
            .buttonStyle(PinnedDirectoryCardButtonStyle())

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
private struct PinnedDirectoryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
