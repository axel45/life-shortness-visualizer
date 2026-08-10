import Foundation
import SwiftData

@MainActor
final class SwiftDataRepository: RepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchUserProfile() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try modelContext.fetch(descriptor).first
    }

    func saveUserProfile(_ profile: UserProfile) async throws {
        modelContext.insert(profile)
        try modelContext.save()
    }

    func deleteAllData() async throws {
        try modelContext.delete(model: CategoryRating.self)
        try modelContext.delete(model: WeekRecord.self)
        try modelContext.delete(model: Category.self)
        try modelContext.delete(model: LifeStage.self)
        try modelContext.delete(model: UserProfile.self)
        try modelContext.save()
        UserDefaults.standard.set(false, forKey: UserDefaultsKey.wallpaperShortcutConfigured)
        UserDefaults.standard.set(false, forKey: UserDefaultsKey.onboardingCompleted)
    }

    func fetchWeekRecords() async throws -> [WeekRecord] {
        let descriptor = FetchDescriptor<WeekRecord>()
        return try modelContext.fetch(descriptor)
    }

    func fetchWeekRecord(lifeWeekIndex: Int) async throws -> WeekRecord? {
        let descriptor = FetchDescriptor<WeekRecord>(
            predicate: #Predicate { $0.lifeWeekIndex == lifeWeekIndex }
        )
        return try modelContext.fetch(descriptor).first
    }

    func saveWeekRecord(_ record: WeekRecord) async throws {
        if record.modelContext == nil {
            modelContext.insert(record)
        }
        record.updatedAt = Date()
        try modelContext.save()
    }

    func fetchCategories() async throws -> [Category] {
        var descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.order)]
        )
        return try modelContext.fetch(descriptor)
    }

    func saveCategory(_ category: Category) async throws {
        if category.modelContext == nil {
            modelContext.insert(category)
        }
        category.updatedAt = Date()
        try modelContext.save()
    }

    func deleteCategory(_ category: Category) async throws {
        let categoryId = category.id
        let ratings = try modelContext.fetch(
            FetchDescriptor<CategoryRating>(predicate: #Predicate { $0.categoryId == categoryId })
        )
        for rating in ratings { modelContext.delete(rating) }
        category.isActive = false
        category.updatedAt = Date()
        try modelContext.save()
    }

    func fetchLifeStages() async throws -> [LifeStage] {
        let descriptor = FetchDescriptor<LifeStage>(
            sortBy: [SortDescriptor(\.order)]
        )
        return try modelContext.fetch(descriptor)
    }

    func saveLifeStage(_ stage: LifeStage) async throws {
        if stage.modelContext == nil {
            modelContext.insert(stage)
        }
        stage.updatedAt = Date()
        try modelContext.save()
    }

    func deleteLifeStage(_ stage: LifeStage) async throws {
        modelContext.delete(stage)
        try modelContext.save()
    }
}

enum UserDefaultsKey {
    static let onboardingCompleted = "onboardingCompleted"
    static let wallpaperShortcutConfigured = "wallpaperShortcutConfigured"
    static let lastWallpaperGeneratedAt = "lastWallpaperGeneratedAt"
    static let wallpaperBannerDismissedWeek = "wallpaperBannerDismissedWeek"
    static let notificationsEnabled = "notificationsEnabled"
    static let notificationHour = "notificationHour"
    static let notificationMinute = "notificationMinute"
    static let onboardingCompletedAt = "onboardingCompletedAt"
}
