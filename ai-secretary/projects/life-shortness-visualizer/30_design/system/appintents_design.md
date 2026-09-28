# AppIntents 実装設計書

作成日: 2026年8月4日
ステータス: pending-approval
関連: 30_design/system/architecture.md

---

## 1. 概要

iOS のショートカットApp と連携するための `AppIntents` フレームワーク実装仕様。
壁紙の自動更新を「毎週月曜 朝7時に自動実行」するためのエントリーポイントを提供する。

**iOS制約の確認**
- アプリから直接ホーム画面・ロック画面の壁紙を変更するAPIは非公開 → App Store審査でリジェクト対象
- `AppIntents` でショートカットApp に公開したアクションをユーザーが自動化設定することが唯一の合法手段

---

## 2. 実装するIntent一覧

| Intent名 | 説明 | ショートカットApp表示名 |
|---------|------|----------------------|
| `GenerateWallpaperIntent` | グリッドを壁紙画像として生成・写真ライブラリに保存 | 「壁紙を更新する」 |

---

## 3. GenerateWallpaperIntent 詳細仕様

### 3.1 定義

```swift
import AppIntents

struct GenerateWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "壁紙を更新する"
    static var description = IntentDescription("人生グリッドの最新状態を壁紙として生成し、写真ライブラリに保存します。")

    // パラメーターなし（ユーザー入力不要）

    func perform() async throws -> some IntentResult {
        // 実装は 3.3 を参照
        return .result()
    }
}
```

### 3.2 処理フロー

```
perform() 呼び出し
  │
  ├─ 1. SwiftDataからデータ取得
  │      UserProfile（生年月日・想定寿命）
  │      WeekRecord（全記録）
  │      Category（カテゴリー一覧）
  │      LifeStage（ライフステージ定義）
  │
  ├─ 2. GridView を ImageRenderer で画像化
  │      解像度: UIScreen.main.scale（2x or 3x）
  │      サイズ: デバイスの画面サイズ（縦向き固定）
  │      フォーマット: PNG
  │
  ├─ 3. 写真ライブラリに保存
  │      アルバム名: "Life in Weeks"
  │      アルバムが存在しない場合は作成
  │      権限: PHPhotoLibrary.requestAuthorization(.addOnly)
  │
  └─ 4. 完了を返す
         成功: .result()
         失敗: throw IntentError.general（エラー内容をログ）
```

### 3.3 実装コード骨格

```swift
func perform() async throws -> some IntentResult {
    // 1. データ取得
    let container = try ModelContainer(for: UserProfile.self, WeekRecord.self, LifeStage.self, Category.self)
    let context = ModelContext(container)
    let profile = try context.fetch(FetchDescriptor<UserProfile>()).first
    guard let profile else { throw IntentError.general }

    // 2. 画像生成
    let gridView = GridView(profile: profile)
        .frame(width: UIScreen.main.bounds.width,
               height: UIScreen.main.bounds.height)
    let renderer = ImageRenderer(content: gridView)
    renderer.scale = UIScreen.main.scale
    guard let uiImage = renderer.uiImage else { throw IntentError.general }

    // 3. 写真ライブラリ保存
    try await WallpaperSaver.save(image: uiImage, toAlbum: "Life in Weeks")

    return .result()
}
```

### 3.4 WallpaperSaver ユーティリティ

```swift
// Utilities/WallpaperSaver.swift
struct WallpaperSaver {
    static func save(image: UIImage, toAlbum albumName: String) async throws {
        // 権限確認
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw WallpaperError.permissionDenied
        }

        // アルバム取得 or 作成
        var album = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any,
            options: nil
        ).firstObject(where: { $0.localizedTitle == albumName })

        if album == nil {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }
            album = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .any, options: nil
            ).firstObject(where: { $0.localizedTitle == albumName })
        }

        // 画像保存
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let album, let placeholder = request.placeholderForCreatedAsset {
                let collectionRequest = PHAssetCollectionChangeRequest(for: album)
                collectionRequest?.addAssets([placeholder] as NSArray)
            }
        }
    }
}
```

---

## 4. App.swift での登録

```swift
// App/LifeInWeeksApp.swift
@main
struct LifeInWeeksApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// AppIntentsは自動検出されるため追加登録不要
// ただし Info.plist の NSPhotoLibraryAddUsageDescription が必要
```

---

## 5. Info.plist 必須エントリ

| キー | 値（ユーザー表示文） |
|------|------------------|
| `NSPhotoLibraryAddUsageDescription` | 「生成した壁紙画像を「Life in Weeks」アルバムに保存するために使用します。」 |

---

## 6. ショートカットApp 自動化設定手順（O03 ガイドの内容）

ユーザーが初回1回だけ行う設定。O03画面でステップバイステップに案内する。

```
ステップ1: ショートカットApp を開く
  → アプリ内の「ショートカットAppを開く」ボタンで直接遷移
  → URL: shortcuts://

ステップ2: 「オートメーション」タブ → 「＋」
  → 「時刻」を選択
  → 毎週 月曜日 07:00 に設定

ステップ3: 「アクションを追加」
  → 「Life in Weeks」で検索
  → 「壁紙を更新する」を選択

ステップ4: 「実行前に確認」をオフにする
  → オフにしないと毎週確認ダイアログが出る

ステップ5: 「完了」をタップ
  → アプリに戻り「設定完了」ボタンをタップ
  → UserDefaults に wallpaperShortcutConfigured = true を保存
```

---

## 7. 壁紙画像の仕様

| 項目 | 仕様 |
|------|------|
| サイズ | デバイスのネイティブ解像度（`UIScreen.main.bounds` × `UIScreen.main.scale`） |
| フォーマット | PNG |
| 向き | 縦向き固定（Portrait） |
| レンダリング対象 | GridView（ライフステージバー＋ドットグリッド＋下部統計バー）。タブバー・FABは含まない |
| 保存先アルバム | "Life in Weeks"（なければ自動作成） |
| 上書き方式 | 新規保存（削除はしない）。アルバム内の最新画像が壁紙設定対象 |

---

## 8. エラーハンドリング

| エラー | 原因 | 対応 |
|--------|------|------|
| 写真ライブラリ権限なし | ユーザーが権限を拒否 | ショートカット実行時に設定アプリへの誘導バナーを表示 |
| UserProfile未作成 | オンボーディング未完了でIntentが呼ばれた場合 | `IntentError.general` をthrow。ショートカットApp側でエラー表示 |
| ImageRenderer失敗 | メモリ不足 | リトライなし。次の週の自動実行に委ねる |

---

## 9. テスト方針

| テスト項目 | 方法 |
|-----------|------|
| Intent単体動作確認 | Xcodeのショートカットデバッガー（Run > Test AppIntent）で手動実行 |
| 写真ライブラリ保存確認 | シミュレーター + 実機で画像が「Life in Weeks」アルバムに保存されることを目視確認 |
| 自動化トリガー確認 | テスト用に「5分後」にトリガーを設定して動作確認 |
| Reduce Motion / 権限拒否 | エッジケースを手動で再現してエラーハンドリングを確認 |

---

## 10. 将来対応（v2以降）

- ウィジェット対応（WidgetKit）: 現在は非採用。v2以降で検討
- アプリからの壁紙直接設定: Appleが将来APIを公開した場合に切り替える
- 複数解像度の壁紙生成: iPad対応時に縦横両方を生成する
