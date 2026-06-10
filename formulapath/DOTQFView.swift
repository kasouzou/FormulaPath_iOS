// DOTQF=Derivation of the quadratic formula=2次方程式の解の公式の導出

//
//  DOTQFView.swift
//
//

import SwiftUI

struct DOTQFView: View {
    // カプセル化されたステージの状態（MVP用の仮データ。本来はViewModel等から受け取るイメージだよ）
    @State private var currentEquation: String = "ax² + bx + c = 0"
    @State private var questionText: String = "まずは定数項 c を右辺に移項して、両辺を a で割ってみよう。どんな式になる？"
    
    // 3択か4択かを動的に試せるように、ここでは3つの選択肢を用意
    @State private var choices: [String] = [
        "x² + (b/a)x = -c/a",
        "x² + bx = -c",
        "x² + (b/a)x = c/a"
    ]
    
    var body: some View {
        ZStack {
            // 背景を薄いシステム背景色に
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 【上部：数式表示ゾーン】
                VStack(spacing: 16) {
                    Text(questionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    // メインの数式ボード（ほんのりピンクの枠線でFormulaPathらしさをプラス）
                    Text(currentEquation)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .minimumScaleFactor(0.5)
                        .italic()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180) // ワイヤーフレームの縦長ゾーンを意識
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 16, y: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(LinearGradient(colors: [.pink.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // 【下部：3択または4択ゾーン】
                VStack(spacing: 14) {
                    if choices.count == 4 {
                        // 4択の場合は綺麗な2x2グリッド
                        VStack(spacing: 14) {
                            HStack(spacing: 14) {
                                ChoiceButton(text: choices[0]) { handleChoice(at: 0) }
                                ChoiceButton(text: choices[1]) { handleChoice(at: 1) }
                            }
                            HStack(spacing: 14) {
                                ChoiceButton(text: choices[2]) { handleChoice(at: 2) }
                                ChoiceButton(text: choices[3]) { handleChoice(at: 3) }
                            }
                        }
                    } else {
                        // 3択の場合は上が2つ、下が1つの全幅ボタンにして画面のガタつきを防ぐ
                        VStack(spacing: 14) {
                            HStack(spacing: 14) {
                                ChoiceButton(text: choices[0]) { handleChoice(at: 0) }
                                ChoiceButton(text: choices[1]) { handleChoice(at: 1) }
                            }
                            if choices.count > 2 {
                                ChoiceButton(text: choices[2], isFullWidth: true) { handleChoice(at: 2) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("解の公式の導出")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // ボタンがタップされた時のアクション
    private func handleChoice(at index: Int) {
        // TODO: 正誤判定や次のステップへの遷移ロジックをここに書くよ
        print("Selected index: \(index)")
    }
}


#Preview {
    NavigationStack {
        DOTQFView()  
    }
}

