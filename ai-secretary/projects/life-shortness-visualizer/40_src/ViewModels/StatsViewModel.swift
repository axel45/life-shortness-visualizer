import Foundation
import Observation

struct CategoryStat: Identifiable {
    let id: UUID
    let name: String
    let weeklyData: [(weekIndex: Int, average: Double)]
    var streak: Int
    var totalAverage: Double
}

@Observable
@MainActor
final class StatsViewModel {
    var categorieStats: [CategoryStat] = []
    var lifeConsumedPercent: Double = 0
    var userProfile: UserProfile?
    var errorMessage: String? = nil

    private let repository: RepositoryProtocol

    init(repository: RepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        do {
            userProfile = try await repository.fetchUserProfile()
            let categories = try await repository.fetchCategories()
            let records = try await repository.fetchWeekRecords()
            let sorted = records.sorted { $0.lifeWeekIndex < $1.lifeWeekIndex }

            guard let profile = userProfile else { return }
            let currentIndex = WeekCalculator.lifeWeekIndex(from: profile.birthDate)
            lifeConsumedPercent = Double(currentIndex) / Double(profile.lifeExpectancy * 52) * 100

            categorieStats = categories.map { category in
                let weekly: [(weekIndex: Int, average: Double)] = sorted.compactMap { record in
                    guard let rating = record.rating(for: category.id), rating.stars > 0 else { return nil }
                    return (record.lifeWeekIndex, Double(rating.stars))
                }

                let total = weekly.isEmpty ? 0.0 : weekly.reduce(0) { $0 + $1.average } / Double(weekly.count)
                let streak = calculateStreak(records: sorted, categoryId: category.id, currentIndex: currentIndex)

                return CategoryStat(id: category.id, name: category.name, weeklyData: weekly, streak: streak, totalAverage: total)
            }
        } catch {
            errorMessage = "統計データの読み込みに失敗しました"
        }
    }

    private func calculateStreak(records: [WeekRecord], categoryId: UUID, currentIndex: Int) -> Int {
        var streak = 0
        var index = currentIndex

        while index >= 0 {
            guard let record = records.first(where: { $0.lifeWeekIndex == index }),
                  let rating = record.rating(for: categoryId),
                  rating.stars >= 3 else { break }
            streak += 1
            index -= 1
        }
        return streak
    }
}
