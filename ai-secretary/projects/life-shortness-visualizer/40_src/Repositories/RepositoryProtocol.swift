import Foundation

@MainActor
protocol RepositoryProtocol {
    func fetchUserProfile() async throws -> UserProfile?
    func saveUserProfile(_ profile: UserProfile) async throws
    func deleteAllData() async throws

    func fetchWeekRecords() async throws -> [WeekRecord]
    func fetchWeekRecord(lifeWeekIndex: Int) async throws -> WeekRecord?
    func saveWeekRecord(_ record: WeekRecord) async throws

    func fetchCategories() async throws -> [Category]
    func saveCategory(_ category: Category) async throws
    func deleteCategory(_ category: Category) async throws

    func fetchLifeStages() async throws -> [LifeStage]
    func saveLifeStage(_ stage: LifeStage) async throws
    func deleteLifeStage(_ stage: LifeStage) async throws
}
