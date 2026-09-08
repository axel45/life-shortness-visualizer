import SwiftUI
import UIKit

struct WallpaperGuideView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

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

                VStack(alignment: .leading, spacing: 12) {
                    stepRow(number: 1, text: "ショートカットAppを開く")
                    stepRow(number: 2, text: "「オートメーション」→「+」をタップ")
                    stepRow(number: 3, text: "「時刻」→「毎週月曜 7:00」を設定")
                    stepRow(number: 4, text: "「壁紙を生成して保存」アクションを追加")
                    stepRow(number: 5, text: "「壁紙を設定」アクションを追加し、写真ライブラリから最新の画像を選択")
                    stepRow(number: 6, text: "「実行時に通知: オフ」に設定して完了")
                }
                .padding(.horizontal, 32)

                Text("※ アプリが写真に壁紙画像を保存 → ショートカットが壁紙として設定する、という2ステップで動作します")
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
        }
    }
}
