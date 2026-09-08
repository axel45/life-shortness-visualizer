import SwiftUI
import UIKit

struct WallpaperGuideView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 56))
                        .foregroundStyle(.yellow)

                    Text("壁紙を自動更新する")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("ショートカットAppで「毎週月曜 7:00」の自動化を設定すると、毎週人生カレンダーが壁紙として更新されます。")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 16) {
                    stepRow(number: 1, text: "ショートカットAppを開く")
                    stepRow(number: 2, text: "「オートメーション」→「+」をタップ")
                    stepRow(
                        number: 3,
                        title: "時刻と繰り返しを設定",
                        detail: "「時刻」を選択 → 時刻「7:00」を入力 → 「繰り返し」で「毎週」を選び曜日（例: 月曜）を指定 → 「すぐに実行」を選択（確認なしで自動実行）"
                    )
                    stepRow(number: 4, text: "「4420 Life」→「壁紙を更新」を選択。グリッド画像の生成・保存が自動で行われます")
                    stepRow(number: 5, text: "「壁紙を設定」アクションを追加し、写真ライブラリから最新の画像を選択して壁紙として設定")
                }
                .padding(.horizontal, 32)

                Text("※ アプリが写真にグリッド画像を保存 → ショートカットが壁紙として設定する、という2ステップで動作します")
                    .font(.caption)
                    .foregroundStyle(Color(white: 0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "shortcuts://automations") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("オートメーションを開く")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button("後で設定する", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.5))
                        .frame(height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.gray)
                            .padding(12)
                    }
                }
                Spacer()
            }
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(Color.yellow)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(Color.yellow)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color(white: 0.8))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color(white: 0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
