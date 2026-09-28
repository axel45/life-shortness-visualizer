import Foundation
import SwiftData

@Model
final class WeekRecord {
    var id: UUID
    var lifeWeekIndex: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var ratings: [CategoryRating]

    init(lifeWeekIndex: Int) {
        self.id = UUID()
        self.lifeWeekIndex = lifeWeekIndex
        self.ratings = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var averageStars: Double? {
        let rated = ratings.filter { $0.stars > 0 }
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0) { $0 + $1.stars }) / Double(rated.count)
    }

    func rating(for categoryId: UUID) -> CategoryRating? {
        ratings.first { $0.categoryId == categoryId }
    }
}
