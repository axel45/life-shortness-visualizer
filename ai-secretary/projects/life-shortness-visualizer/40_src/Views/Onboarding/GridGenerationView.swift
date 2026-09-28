import SwiftUI
import UIKit

struct GridGenerationView: View {
    let birthDate: Date
    let lifeExpectancy: Int
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cols = Constants.weeksPerYear
    private let dotSize: CGFloat = 4
    private let dotSpacing: CGFloat = 1
    private let animationDuration: Double = 2.5

    private var rows: Int { lifeExpectancy }
    private var currentLifeWeekIndex: Int { WeekCalculator.lifeWeekIndex(from: birthDate) }

    @State private var startDate: Date? = nil
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if reduceMotion {
                    dotGrid(progress: 1.1)
                } else {
                    TimelineView(.animation) { timeline in
                        let elapsed = startDate.map { timeline.date.timeIntervalSince($0) } ?? 0
                        let progress = min(elapsed / animationDuration, 1.1)
                        dotGrid(progress: progress)
                    }
                }

                Spacer().frame(height: 48)

                VStack(spacing: 6) {
                    Text("あなたの人生は")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.55))
                    Text("\(currentLifeWeekIndex)週目")
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("を迎えています")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.55))
                }
                .opacity(textOpacity)

                Spacer()

                Button {
                    onComplete()
                } label: {
                    Text("確認する")
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
            if reduceMotion {
                textOpacity = 1
                buttonOpacity = 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                startDate = Date()
                withAnimation(.easeIn(duration: 0.7).delay(animationDuration)) {
                    textOpacity = 1
                }
                withAnimation(.easeIn(duration: 0.5).delay(animationDuration + 0.9)) {
                    buttonOpacity = 1
                }
                Task {
                    try? await Task.sleep(nanoseconds: UInt64((animationDuration + 0.2) * 1_000_000_000))
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    private func dotGrid(progress: Double) -> some View {
        let cell = dotSize + dotSpacing
        let gridWidth = CGFloat(cols) * cell - dotSpacing
        let gridHeight = CGFloat(rows) * cell - dotSpacing
        let current = currentLifeWeekIndex

        return Canvas { context, _ in
            for row in 0..<rows {
                for col in 0..<cols {
                    let index = row * cols + col
                    let opacity = dotOpacity(for: index, current: current, progress: progress)
                    guard opacity > 0 else { continue }

                    let x = CGFloat(col) * cell
                    let y = CGFloat(row) * cell
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)

                    if index == current {
                        let ringRect = rect.insetBy(dx: -1.5, dy: -1.5)
                        context.stroke(
                            Path(ellipseIn: ringRect),
                            with: .color(Color.yellow.opacity(opacity)),
                            lineWidth: 1.5
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.45).opacity(opacity)))
                    } else {
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(pastDotColor(for: index, current: current).opacity(opacity))
                        )
                    }
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight)
    }

    private func dotOpacity(for index: Int, current: Int, progress: Double) -> Double {
        if index <= current {
            let fraction = current > 0 ? Double(index) / Double(current) : 1.0
            return max(0, min(1, (progress - fraction * 0.88) / 0.06))
        } else {
            return max(0, min(1, (progress - 0.95) / 0.05))
        }
    }

    private func pastDotColor(for index: Int, current: Int) -> Color {
        if index > current {
            return Color(white: 0.13)
        }
        switch index % 11 {
        case 0:       return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 1, 2:    return Color(white: 0.76)
        case 3, 4, 5: return Color(white: 0.92)
        default:      return Color(white: 0.35)
        }
    }
}
