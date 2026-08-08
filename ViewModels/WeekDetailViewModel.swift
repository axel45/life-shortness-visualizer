import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class WeekDetailViewModel {
    var weekRecord: WeekRecord?
    var categories: [Category] = []
    var userProfile: UserProfile?
    var errorMessage: String? = nil

    private let repository: RepositoryProtocol

    init(repository: RepositoryProtocol) {
        self.repository = repository
    }

    var lifeWeekIndex: Int = 0

    var dateRange: String {
        guard let profile = userProfile else { return "" }
        return WeekCalculator.formattedDateRange(lifeWeekIndex: lifeWeekIndex, birthDate: profile.birthDate)
    }

    var age: Int {
        WeekCalculator.age(lifeWeekIndex: lifeWeekIndex)
    }

    func load(lifeWeekIndex: Int) async {
        self.lifeWeekIndex = lifeWeekIndex
        do {
            userProfile = try await repository.fetchUserProfile()
            categories = try await repository.fetchCategories()
            weekRecord = try await repository.fetchWeekRecord(lifeWeekIndex: lifeWeekIndex)
        } catch {
            errorMessage = "データの読み込みに失敗しました"
        }
    }

    func stars(for category: Category) -> Int {
        weekRecord?.rating(for: category.id)?.stars ?? 0
    }

    /// Fix 16: Immediately update local UI state (optimistic update) before async save.
    func setStarsOptimistic(_ stars: Int, for category: Category) {
        if weekRecord == nil {
            let newRecord = WeekRecord(lifeWeekIndex: lifeWeekIndex)
            weekRecord = newRecord
        }
        guard let record = weekRecord else { return }
        if let existing = record.rating(for: category.id) {
            existing.stars = stars
            existing.updatedAt = Date()
        } else {
            let rating = CategoryRating(weekRecordId: record.id, categoryId: category.id, stars: stars)
            rating.weekRecord = record
            record.ratings.append(rating)
        }
    }

    func setStars(_ stars: Int, for category: Category) async {
        do {
            if weekRecord == nil {
                let newRecord = WeekRecord(lifeWeekIndex: lifeWeekIndex)
                weekRecord = newRecord
                try await repository.saveWeekRecord(newRecord)
            }
            guard let record = weekRecord else { return }

            if let existing = record.rating(for: category.id) {
                existing.stars = stars
                existing.updatedAt = Date()
            } else {
                let rating = CategoryRating(weekRecordId: record.id, categoryId: category.id, stars: stars)
                rating.weekRecord = record
                record.ratings.append(rating)
            }
            try await repository.saveWeekRecord(record)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = "記録の保存に失敗しました"
        }
    }
}
