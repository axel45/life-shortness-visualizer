import SwiftUI
import SwiftData
import Observation
import UIKit

@Observable
@MainActor
final class GridViewModel {
    var userProfile: UserProfile?
    var weekRecords: [WeekRecord] = []
    private(set) var weekRecordMap: [Int: WeekRecord] = [:]
    var selectedLifeWeekIndex: Int = 0
    var isWeekDetailPresented: Bool = false
    var showWallpaperBanner: Bool = false
    var errorMessage: String? = nil

    private let repository: RepositoryProtocol

    init(repository: RepositoryProtocol) {
        self.repository = repository
    }

    var currentLifeWeekIndex: Int {
        guard let profile = userProfile else { return 0 }
        return WeekCalculator.lifeWeekIndex(from: profile.birthDate)
    }

    var isSelectedWeekRecorded: Bool {
        guard let record = weekRecordMap[selectedLifeWeekIndex] else { return false }
        return record.ratings.contains { $0.stars > 0 }
    }

    var totalWeeks: Int {
        Constants.defaultLifeExpectancy * Constants.weeksPerYear
    }

    /// Selects a week (shows yellow ring) without opening the edit sheet.
    func selectWeekOnly(_ lifeWeekIndex: Int) {
        // Future weeks are non-selectable (Fix 14)
        guard lifeWeekIndex <= currentLifeWeekIndex else { return }
        selectedLifeWeekIndex = lifeWeekIndex
    }

    /// Opens the edit sheet for the currently selected week.
    func openWeekDetail() {
        guard selectedLifeWeekIndex <= currentLifeWeekIndex else { return }
        isWeekDetailPresented = true
    }

    func selectCurrentWeek() {
        selectedLifeWeekIndex = currentLifeWeekIndex
        isWeekDetailPresented = true
    }

    /// Reload week records after a save in WeekDetailSheet (Fix 15).
    func reloadAfterSave() {
        Task {
            do {
                weekRecords = try await repository.fetchWeekRecords()
                weekRecordMap = Dictionary(uniqueKeysWithValues: weekRecords.map { ($0.lifeWeekIndex, $0) })
            } catch {
                errorMessage = "データの更新に失敗しました"
            }
        }
    }

    func loadData() async {
        do {
            userProfile = try await repository.fetchUserProfile()
            weekRecords = try await repository.fetchWeekRecords()
            weekRecordMap = Dictionary(uniqueKeysWithValues: weekRecords.map { ($0.lifeWeekIndex, $0) })
            selectedLifeWeekIndex = currentLifeWeekIndex
            checkWallpaperBanner()
        } catch {
            errorMessage = "データの読み込みに失敗しました"
        }
    }

    private func checkWallpaperBanner() {
        let calendar = Calendar.current
        guard calendar.isDateInMonday(Date()) else { return }

        let lastGenerated = UserDefaults.standard.object(forKey: UserDefaultsKey.lastWallpaperGeneratedAt) as? Date
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 86400)

        guard let last = lastGenerated, last < sevenDaysAgo else {
            showWallpaperBanner = false
            return
        }

        let dismissedWeek = UserDefaults.standard.integer(forKey: UserDefaultsKey.wallpaperBannerDismissedWeek)
        guard dismissedWeek != currentLifeWeekIndex else {
            showWallpaperBanner = false
            return
        }

        showWallpaperBanner = true
    }

    func dismissWallpaperBanner() {
        UserDefaults.standard.set(currentLifeWeekIndex, forKey: UserDefaultsKey.wallpaperBannerDismissedWeek)
        showWallpaperBanner = false
    }

    func generateWallpaper() async {
        guard let profile = userProfile else { return }
        let screenSize = UIScreen.main.bounds.size
        do {
            try await WallpaperRenderer.generateAndSave(
                profile: profile,
                weekRecords: weekRecords,
                screenSize: screenSize
            )
            dismissWallpaperBanner()
        } catch WallpaperError.photoPermissionDenied {
            errorMessage = "写真ライブラリへのアクセスが許可されていません。設定アプリ > Life in Weeks から許可してください"
        } catch {
            errorMessage = "壁紙の生成に失敗しました"
        }
    }
}

extension Calendar {
    func isDateInMonday(_ date: Date) -> Bool {
        component(.weekday, from: date) == 2
    }
}
