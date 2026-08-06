import AppIntents
import SwiftData
import UIKit

struct GenerateWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "壁紙を生成して保存"
    static let description = IntentDescription("人生グリッドを生成し、写真ライブラリに保存します")

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: UserProfile.self, Category.self, WeekRecord.self, CategoryRating.self, LifeStage.self)
        let context = container.mainContext
        let repo = SwiftDataRepository(modelContext: context)

        guard let profile = try await repo.fetchUserProfile() else {
            throw IntentError.noProfile
        }

        let weekRecords = try await repo.fetchWeekRecords()
        let lifeStages = try await repo.fetchLifeStages()
        let screenSize = UIScreen.main.bounds.size

        do {
            try await WallpaperRenderer.generateAndSave(
                profile: profile,
                weekRecords: weekRecords,
                screenSize: screenSize
            )
        } catch WallpaperError.photoPermissionDenied {
            throw IntentError.photoPermissionDenied
        }

        return .result()
    }
}

enum IntentError: Error, LocalizedError {
    case noProfile
    case photoPermissionDenied

    var errorDescription: String? {
        switch self {
        case .noProfile:
            return "プロフィールが設定されていません。アプリを開いて生年月日を入力してください"
        case .photoPermissionDenied:
            return "写真ライブラリへのアクセスが許可されていません。設定アプリから許可してください"
        }
    }
}
