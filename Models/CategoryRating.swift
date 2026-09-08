import Foundation
import SwiftData

@Model
final class CategoryRating {
    var id: UUID
    var weekRecordId: UUID
    var categoryId: UUID
    var stars: Int  // 0=未評価, 1〜5=評価済み
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \WeekRecord.ratings)
    var weekRecord: WeekRecord?

    init(weekRecordId: UUID, categoryId: UUID, stars: Int = 0) {
        self.id = UUID()
        self.weekRecordId = weekRecordId
        self.categoryId = categoryId
        self.stars = max(0, min(5, stars))
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
