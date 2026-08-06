import SwiftUI

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

                    Text("ショートカットAppで「毎週月曜 7:00」の自動化を設定すると、毎週グリッドが壁紙として更新されます。")
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
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        UserDefaults.standard.set(true, forKey: UserDefaultsKey.wallpaperShortcutConfigured)
                        onComplete()
                    } label: {
                        Text("設定した")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button("あとで設定する", action: onSkip)
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
