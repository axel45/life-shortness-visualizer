import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void

    @State private var startDate: Date? = nil
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    private let rows = 18
    private let cols = 26
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 3
    private let animationDuration: Double = 1.6
    // 約36歳相当（18*26*0.42 ≒ 197）
    private let pastCutoff = 197

    private func dotColor(at index: Int) -> Color {
        guard index < pastCutoff else {
            return Color(white: 0.13)
        }
        switch index % 11 {
        case 0:
            return Color(red: 1.0, green: 0.84, blue: 0.0)   // gold
        case 1, 2:
            return Color(white: 0.76)                         // silver
        case 3, 4, 5:
            return Color(white: 0.92)                         // white
        default:
            return Color(white: 0.30)                         // gray
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TimelineView(.animation) { timeline in
                    let elapsed = startDate.map { timeline.date.timeIntervalSince($0) } ?? 0
                    let progress = min(elapsed / animationDuration, 1.1)
                    dotGrid(progress: progress)
                }

                Spacer().frame(height: 52)

                VStack(spacing: 14) {
                    Text("人生は、4,420個の週でできている")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("あなたはいま、何週目にいますか？")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.5))
                }
                .opacity(textOpacity)
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    onComplete()
                } label: {
                    Text("始める")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(buttonOpacity)
            }
        }
        .onAppear {
            startDate = Date()
            withAnimation(.easeIn(duration: 0.8).delay(animationDuration - 0.2)) {
                textOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.6).delay(animationDuration + 0.5)) {
                buttonOpacity = 1
            }
        }
    }

    private func dotGrid(progress: Double) -> some View {
        let cell = dotSize + dotSpacing
        let gridWidth = CGFloat(cols) * cell - dotSpacing
        let gridHeight = CGFloat(rows) * cell - dotSpacing
        let total = rows * cols

        return Canvas { context, _ in
            for row in 0..<rows {
                for col in 0..<cols {
                    let index = row * cols + col
                    let fraction = Double(index) / Double(total)
                    let opacity = max(0, min(1, (progress - fraction) / 0.06))
                    guard opacity > 0 else { continue }

                    let x = CGFloat(col) * cell
                    let y = CGFloat(row) * cell
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(dotColor(at: index).opacity(opacity))
                    )
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight)
    }
}
