# システムアーキテクチャ設計書

作成日: 2026年8月2日
ステータス: pending-approval

---

## 1. 技術スタック

| 項目 | 採用技術 | 理由 |
|------|---------|------|
| 言語 | Swift 5.9+ | iOS開発標準 |
| UI | SwiftUI | 宣言的UIでグリッド・アニメーション実装が容易 |
| グリッドレイアウト | Canvas（SwiftUI） | 4,160個の丸を単一ビューで一括描画。個別Circle()ビュー×4,160は重いためCanvas必須。iOS 15以上対応 |
| データ | SwiftData | iCloudKit連携が標準サポート、将来のバックエンド移行も想定 |
| 同期 | CloudKit（SwiftData経由） | iCloud同期の実装コストが最小 |
| グラフ | Swift Charts | Apple標準、SwiftUIとの親和性が高い |
| 壁紙画像生成 | ImageRenderer（SwiftUI） | SwiftUIビューを画像化、iOS 16以上対応 |
| 壁紙自動化 | AppIntents | ショートカットApp連携、iOS 16以上対応 |
| 最小サポート | iOS 17以上 | ScrollView in Widget、AppIntentsの安定版 |

---

## 2. アーキテクチャパターン

**MVVM（Model - View - ViewModel）** を採用する。

```
View（SwiftUI）
  ↕
ViewModel（@Observable）
  ↕
Model（SwiftData）
  ↕
Repository（抽象化層）← 将来のバックエンド移行をここで吸収
  ↕
CloudKit（iCloud）
```

### Repository層を挟む理由
要件通り「将来的に自前サーバーへ移行」する際、ViewModel以上のコードを変更せずにバックエンドを差し替えられる。

---

## 3. データモデル設計

```swift
// ユーザープロフィール（端末に1件のみ）
UserProfile
  - id: UUID
  - birthDate: Date          // 生年月日（オンボーディングで必須入力）
  - lifeExpectancy: Int      // 想定寿命（デフォルト85）
  - createdAt: Date

// 目標カテゴリー（最大5件）
Category
  - id: UUID
  - name: String             // カテゴリー名
  - order: Int               // 並び順
  - isActive: Bool

// 週次記録（週ごとに1件）
WeekRecord
  - id: UUID
  - lifeWeekIndex: Int       // 誕生週=0 の人生通し週番号（weekStartDateは廃止→db_design.md参照）
  - createdAt: Date
  - updatedAt: Date
  - ratings: [CategoryRating]  // カテゴリーごとの評価

// カテゴリー評価
CategoryRating
  - id: UUID
  - categoryId: UUID
  - stars: Int               // 1〜5（0=未記録）

// ライフステージ
LifeStage
  - id: UUID
  - name: String             // ステージ名
  - startAge: Int            // 開始年齢
  - endAge: Int              // 終了年齢
  - color: String            // カラーコード（HEX）
  - order: Int               // 並び順
```

---

## 4. グリッドの丸の色決定ロジック

更新日: 2026-08-09（カラースキーム刷新 v1.3.0）

```
週の状態を判定する関数 ColorResolver.dotColor(for:isFuture:)

1. isFuture == true（未来の週）
   → チャコールグレー（#48484A）・ドットサイズ通常の50%（小さいドット）

2. weekRecord が nil / averageStars が nil（未記録）
   → チャコールグレー（#48484A）・通常サイズ

3. averageStars > 4.5
   → サンシャイン（#FFE566）

4. それ以外（averageStars ≦ 4.5）
   → ライトグレー（#AEAEB2）
```

選択インジケータ: ソフトホワイト（#F2F2F7）の外周リング 1.5pt

設計方針:
- 良い週だけが黄色に「光る」ミニマルな世界観。平均以下はグレー階調に収束させる
- 未来（小さい）・未記録（通常グレー）はサイズだけで区別（色は同じ #48484A）
- 評価段階を2段階（ライトグレー / サンシャイン）に絞り、認知負荷を最小化
- 閾値 4.5 超：5カテゴリー全★5 or 4★中心で一部★5など、意識的に良い週だけ光る

---

## 5. 壁紙自動更新フロー

```
【AppIntent実装】
GenerateWallpaperIntent: AppIntent
  1. SwiftDataから最新の WeekRecord を取得
  2. GridView（SwiftUI）を ImageRenderer で壁紙解像度に画像化
  3. 写真ライブラリの「Life in Weeks」アルバムに保存
  4. 完了を返す

【ショートカット自動化（ユーザーが初回設定）】
毎週月曜 07:00
  → GenerateWallpaperIntent を実行
  → 「Life in Weeks」アルバムの最新画像を取得
  → ホーム画面・ロック画面の壁紙に設定
```

---

## 6. 画像レンダリング仕様

| 項目 | 仕様 |
|------|------|
| 解像度 | 端末のネイティブ解像度（UIScreen.main.scale を使用） |
| サイズ | 端末画面サイズに合わせて動的計算 |
| フォーマット | PNG |
| レンダリング対象 | GridView（ライフステージバー＋ドットグリッド＋下部統計） |

---

## 7. モジュール構成

```
LifeInWeeks/
├── App/
│   └── LifeInWeeksApp.swift       # エントリーポイント・SwiftData設定・MainTabView
├── Models/
│   ├── UserProfile.swift
│   ├── Category.swift
│   ├── WeekRecord.swift
│   ├── CategoryRating.swift
│   └── LifeStage.swift
├── Repositories/
│   ├── RepositoryProtocol.swift   # 抽象化インターフェース
│   └── SwiftDataRepository.swift  # iCloud実装
├── ViewModels/
│   ├── GridViewModel.swift
│   ├── WeekDetailViewModel.swift
│   ├── StatsViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Grid/
│   │   ├── GridView.swift         # メイン画面（.padding(.horizontal, 8) 追加）
│   │   └── DotGridCanvas.swift    # Canvas描画・スワイプ操作
│   ├── WeekDetail/
│   │   └── WeekDetailSheet.swift  # 記録シート（記録タブからもここを使用）
│   ├── Stats/
│   │   └── StatsSheet.swift
│   ├── Settings/
│   │   ├── SettingsView.swift     # カテゴリー追加・削除UI含む
│   │   └── LifeStageEditView.swift
│   └── Onboarding/
│       ├── BirthDateInputView.swift
│       ├── WallpaperGuideView.swift
│       └── CategorySetupView.swift
├── AppIntents/
│   └── GenerateWallpaperIntent.swift
└── Utilities/
    ├── WeekCalculator.swift        # ISO 8601週計算
    ├── ColorResolver.swift         # 丸の色決定ロジック
    └── WallpaperRenderer.swift     # ImageRenderer ラッパー
```

---

## 8. iCloud同期方針

- SwiftDataの `ModelConfiguration` で `cloudKitDatabase: .automatic` を指定するだけで自動同期
- 競合解決はCloudKitのデフォルト（タイムスタンプ優先）を使用
- オフライン時はローカルに保存し、接続回復時に自動同期

---

## 9. 将来の自前サーバー移行方針

`RepositoryProtocol` に準拠した `APIRepository` を追加するだけで移行可能。

```swift
protocol RepositoryProtocol {
    func fetchWeekRecords() async throws -> [WeekRecord]
    func saveWeekRecord(_ record: WeekRecord) async throws
    func fetchLifeStages() async throws -> [LifeStage]
    // ...
}

// 現在
class SwiftDataRepository: RepositoryProtocol { ... }

// 将来
class APIRepository: RepositoryProtocol { ... }
```

---

## 10. セキュリティ設計

### SQLインジェクション・XSS対策

| 脅威 | 対策方針 | 理由 |
|------|---------|------|
| SQLインジェクション | 対策不要（N/A） | SwiftDataはORM（Object-Relational Mapper）を使用しており、生SQLを直接発行しない。パラメーター化クエリが構造的に保証される |
| XSS（クロスサイトスクリプティング） | 対策不要（N/A） | ネイティブiOSアプリのためWebViewを使用しない。HTMLレンダリングは行わないためXSSの攻撃面が存在しない |

---

## 11. キャッシュ戦略

SwiftUIの`@Query`マクロを**意図的に依存対象として採用**する。

| データ種別 | キャッシュ方式 | 詳細 |
|----------|-------------|------|
| WeekRecord（全件） | SwiftData `@Query` の内部キャッシュ | グリッド描画時に全WeekRecordを一括取得。SwiftDataがメモリ内にキャッシュし、変更時のみ再フェッチ |
| Category（マスター） | SwiftData `@Query` の内部キャッシュ | 変更頻度が低いため追加キャッシュ不要 |
| LifeStage（マスター） | SwiftData `@Query` の内部キャッシュ | 同上 |

> **設計方針**: SwiftDataの`@Query`はリアクティブな変更検知とメモリキャッシュを内蔵している。アプリ独自のキャッシュレイヤーを追加することで複雑性が増すため、意図的にSwiftDataのキャッシュに委任する。

---

## 12. デプロイフロー

```
開発環境（Xcode Simulator）
  ↓ 機能開発・単体テスト
  ↓
実機テスト（Xcode → 実機接続）
  ↓ UIテスト・パフォーマンス確認
  ↓
TestFlight（社内ベータ配信）
  ↓ Archive → App Store Connect にアップロード
  ↓ TestFlight External Testing で配信
  ↓ 1〜2週間のベータテスト
  ↓
App Store申請
  ↓ App Store Connect でアプリ情報登録
  ↓ Appleの審査（通常1〜3営業日）
  ↓
App Store公開
```

**環境定義**

| 環境 | 用途 | Bundle ID |
|------|------|----------|
| Debug | ローカル開発・Simulator | com.shogo.lifeinweeks.debug |
| Release | TestFlight + App Store | com.shogo.lifeinweeks |

**TestFlight配信手順（初回）**
1. Xcode > Product > Archive
2. App Store Connect にアップロード
3. TestFlight > 外部テスト > ビルド追加
4. テスター（自分のみ）にメール招待

---

## 13. usertest v2 設計変更

| # | 変更内容 | 詳細 |
|---|---------|------|
| v2-#4 | ライフステージバー廃止 | GridViewからLifeStageBarViewを完全削除。横幅全体にグリッドが広がる |
| v2-#5 | 上下スワイプで年移動 | DotGridCanvasに縦スワイプ追加：±52週（1年）移動 |
| v2-#6 | 選択ドットを黄色リングに | スケール拡大+影 → 外周1.5pt黄色アウトラインに変更 |
| v2-#7 | FABが選択週を開く | `selectCurrentWeek()` → `openWeekDetail()`（選択中の週を開く）|
| v2-#8 | 星の保存バグ修正 | `saveWeekRecord`の挿入チェックを `record.modelContext == nil` に修正 |
| v2-#9 | 寿命設定廃止 | `Constants.defaultLifeExpectancy = 85` に固定。UI・オンボーディングから削除 |
| v2-#10 | FAB廃止・記録タブ追加 | FABボタンを削除。タブバーに「記録」タブを追加し、選択週の記録をRecordView（タブ専用ビュー）で表示 |
| v2-#6b | 選択リングをソフトホワイトに変更 | 黄色リング→白→ソフトホワイト（#F2F2F7）に変更 |
| v3-#1 | カラースキーム刷新 | 未来=小さいチャコールグレー、未記録=チャコールグレー、普通=ライトグレー、avg>4.5=サンシャイン（#FFE566）。旧5段階（赤/白/銀/金）廃止 |
| v3-#2 | グリッド水平パディング追加 | `GridView` の GeometryReader に `.padding(.horizontal, 8)` を追加。左右に余白を設けて視認性を向上 |
| v3-#3 | 設定画面からグリッド期間表示を削除 | プロフィールセクションの `LabeledContent("グリッド期間", value: "80年（固定）")` を削除。全ユーザーで固定のため不要 |
| v3-#4 | スワイプ方向修正 | 右スワイプ→次週、左スワイプ→前週（旧は逆）。「スワイプした方向に選択ドットが動く」自然な挙動に統一 |
| v3-#5 | 記録タブをボトムシートに変更 | `RecordView.swift` を削除。「記録」タブタップ時に `WeekDetailSheet` を `.sheet()` で表示。`TabView(selection:)` + `.onChange` でタブ遷移を横取りし、カレンダータブのまま sheet を呈示 |
| v3-#8 | カテゴリー追加・削除UX | 設定画面にカテゴリー追加ボタン（<5個時のみ表示）・削除ガード（最低1個）・ヘッダーにN/5表示を追加 |

---

## 14. 未決定事項

| No. | 項目 | 検討ポイント |
|-----|------|------------|
| 1 | ★平均の計算方法 | 全カテゴリー単純平均か、カテゴリーに重み付けするか |
| 2 | 写真ライブラリの権限 | 壁紙保存に Photos アクセス権限が必要（ユーザーへの説明文）|
| 3 | アプリ名 | 最終的なアプリ名の確定 |
