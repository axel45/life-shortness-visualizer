import SwiftUI
import Photos

@MainActor
enum WallpaperRenderer {

    static func generateAndSave(
        profile: UserProfile,
        weekRecords: [WeekRecord],
        screenSize: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) async throws {
        let wallpaperView = WallpaperGridView(
            profile: profile,
            weekRecords: weekRecords
        )

        let renderer = ImageRenderer(content: wallpaperView.frame(width: screenSize.width, height: screenSize.height))
        renderer.scale = scale
        renderer.proposedSize = .init(width: screenSize.width, height: screenSize.height)

        guard let image = renderer.uiImage else {
            throw WallpaperError.renderFailed
        }

        guard let data = image.pngData() else { throw WallpaperError.renderFailed }
        try await saveToPhotoLibrary(imageData: data)

        UserDefaults.standard.set(Date(), forKey: UserDefaultsKey.lastWallpaperGeneratedAt)
    }

    private nonisolated static func saveToPhotoLibrary(imageData: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw WallpaperError.photoPermissionDenied
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
            } completionHandler: { success, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}

enum WallpaperError: LocalizedError {
    case renderFailed
    case photoPermissionDenied

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "壁紙の生成に失敗しました"
        case .photoPermissionDenied:
            return "写真ライブラリへのアクセスが許可されていません"
        }
    }
}

struct WallpaperGridView: View {
    let profile: UserProfile
    let weekRecords: [WeekRecord]

    private let columns = Constants.weeksPerYear
    private let dotSize: CGFloat = 6.5
    private let dotSpacing: CGFloat = 2

    private var weekRecordMap: [Int: WeekRecord] {
        Dictionary(uniqueKeysWithValues: weekRecords.map { ($0.lifeWeekIndex, $0) })
    }

    var body: some View {
        ZStack {
            Color.black

            DotGridCanvas(
                rows: profile.lifeExpectancy,
                columns: columns,
                dotSize: dotSize,
                dotSpacing: dotSpacing,
                currentLifeWeekIndex: WeekCalculator.lifeWeekIndex(from: profile.birthDate),
                selectedLifeWeekIndex: nil,
                weekRecordMap: weekRecordMap,
                centeredLayout: true,
                onTap: nil
            )
        }
    }
}
