import SwiftUI

struct DotGridCanvas: View {
    let rows: Int
    let columns: Int
    let dotSize: CGFloat
    let dotSpacing: CGFloat
    let currentLifeWeekIndex: Int
    let selectedLifeWeekIndex: Int?
    let weekRecordMap: [Int: WeekRecord]
    let centeredLayout: Bool
    var onTap: ((Int) -> Void)?
    var onSwipe: ((Int) -> Void)?
    var onVerticalSwipe: ((Int) -> Void)?

    private var cellSize: CGFloat { dotSize + dotSpacing }
    private var futureDotSize: CGFloat { max(2, dotSize * 0.5) }

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let offsetX = centeredLayout ? (size.width - CGFloat(columns) * cellSize) / 2 : 0
                let offsetY = centeredLayout ? (size.height - CGFloat(rows) * cellSize) / 2 : 0

                for row in 0..<rows {
                    for col in 0..<columns {
                        let idx = WeekCalculator.lifeWeekIndex(row: row, col: col)
                        let isFuture = idx > currentLifeWeekIndex
                        let record = weekRecordMap[idx]
                        let dotColor = ColorResolver.dotColor(for: record, isFuture: isFuture)
                        let fill = ColorResolver.color(for: dotColor)

                        let x = offsetX + CGFloat(col) * cellSize
                        let y = offsetY + CGFloat(row) * cellSize

                        // 未来週は小さいドット（セル中央に配置）
                        let actualSize = isFuture ? futureDotSize : dotSize
                        let inset = (dotSize - actualSize) / 2
                        let rect = CGRect(x: x + inset, y: y + inset, width: actualSize, height: actualSize)

                        context.fill(Path(ellipseIn: rect), with: .color(fill))

                        if selectedLifeWeekIndex == idx {
                            let ringPadding: CGFloat = 1.5
                            let ringRect = CGRect(
                                x: x - ringPadding,
                                y: y - ringPadding,
                                width: dotSize + ringPadding * 2,
                                height: dotSize + ringPadding * 2
                            )
                            // ソフトホワイト #F2F2F7
                            context.stroke(Path(ellipseIn: ringRect), with: .color(Color(hex: "F2F2F7")), lineWidth: 1.5)
                        }
                    }
                }
            }
            .gesture(
                onTap.map { handler in
                    SpatialTapGesture().onEnded { value in
                        let offsetX = centeredLayout ? (geo.size.width - CGFloat(columns) * cellSize) / 2 : 0
                        let offsetY = centeredLayout ? (geo.size.height - CGFloat(rows) * cellSize) / 2 : 0
                        let col = Int((value.location.x - offsetX) / cellSize)
                        let row = Int((value.location.y - offsetY) / cellSize)
                        guard row >= 0, row < rows, col >= 0, col < columns else { return }
                        handler(WeekCalculator.lifeWeekIndex(row: row, col: col))
                    }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard let current = selectedLifeWeekIndex else { return }
                        let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                        if isHorizontal {
                            guard let handler = onSwipe else { return }
                            let delta = value.translation.width < 0 ? 1 : -1
                            let next = current + delta
                            guard next >= 0 && next < rows * columns else { return }
                            handler(next)
                        } else {
                            guard let handler = onVerticalSwipe else { return }
                            let delta = value.translation.height < 0 ? -Constants.weeksPerYear : Constants.weeksPerYear
                            let next = current + delta
                            guard next >= 0 && next < rows * columns else { return }
                            handler(next)
                        }
                    }
            )
        }
    }
}
