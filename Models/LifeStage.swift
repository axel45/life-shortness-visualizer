import Foundation
import SwiftData

@Model
final class LifeStage {
    var id: UUID
    var name: String
    var startAge: Int
    var endAge: Int
    var colorHex: String
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    init(name: String, startAge: Int, endAge: Int, colorHex: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.startAge = startAge
        self.endAge = endAge
        self.colorHex = colorHex
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    @MainActor static let defaults: [LifeStage] = [
        LifeStage(name: "未就学児",                    startAge: 0,  endAge: 6,  colorHex: "#8B9BB4", order: 1),
        LifeStage(name: "小学校",                      startAge: 6,  endAge: 12, colorHex: "#7A8FA6", order: 2),
        LifeStage(name: "中学",                        startAge: 12, endAge: 15, colorHex: "#7A87A6", order: 3),
        LifeStage(name: "高校",                        startAge: 15, endAge: 18, colorHex: "#8B87A6", order: 4),
        LifeStage(name: "大学",                        startAge: 18, endAge: 22, colorHex: "#8B7FA6", order: 5),
        LifeStage(name: "社会人なりたて",              startAge: 22, endAge: 27, colorHex: "#D4A017", order: 6),
        LifeStage(name: "プロジェクトリーダー（仮）",  startAge: 27, endAge: 32, colorHex: "#FFD700", order: 7),
        LifeStage(name: "マネージャー（仮）",          startAge: 32, endAge: 40, colorHex: "#DAA520", order: 8),
        LifeStage(name: "マネージャー以降のキャリア",  startAge: 40, endAge: 65, colorHex: "#8B7355", order: 9),
        LifeStage(name: "老後",                        startAge: 65, endAge: 85, colorHex: "#696969", order: 10),
    ]
}
