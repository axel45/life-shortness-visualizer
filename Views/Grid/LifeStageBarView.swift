import SwiftUI

struct LifeStageBarView: View {
    let lifeStages: [LifeStage]
    let lifeExpectancy: Int
    let width: CGFloat
    let dotSize: CGFloat
    let dotSpacing: CGFloat

    private var cellSize: CGFloat { dotSize + dotSpacing }
    private var totalHeight: CGFloat { CGFloat(lifeExpectancy) * cellSize }

    var body: some View {
        Canvas { context, size in
            for stage in lifeStages {
                let startY = CGFloat(stage.startAge) * cellSize
                let endY = CGFloat(min(stage.endAge, lifeExpectancy)) * cellSize
                let rect = CGRect(x: 0, y: startY, width: width, height: endY - startY - 1)
                let path = Path(roundedRect: rect, cornerRadius: 2)
                context.fill(path, with: .color(Color(hex: stage.colorHex)))
            }
        }
        .frame(width: width, height: totalHeight)
    }
}
