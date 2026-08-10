# プロジェクト進捗ステータス

プロジェクト名: life-shortness-visualizer（人生の短さ可視化アプリ）
最終更新: 2026年8月5日

---

## フェーズサマリー

| フェーズ | 名称 | ステータス | スコア | 判定 | レビューファイル |
|---------|------|-----------|-------|------|----------------|
| Phase 1 | 企画 | ✅ 完了 | 23/25 | ✅ 合格 | `10_planning/review_phase01.md` |
| Phase 2 | 要件定義 | ✅ 完了 | 19/23 | ✅ 合格 | `20_requirements/review_phase02.md` |
| Phase 3 | 設計 | ✅ 完了 | 22/27* | ✅ 合格 | `30_design/review_phase03.md` |
| Phase 4 | 実装 | ✅ 完了 | 22/25 | ✅ 合格 | `40_src/review_phase04.md` |
| Phase 5 | テスト | ✅ 完了 | 20/24 | ✅ 合格 | `50_testing/review_phase05.md` |
| Phase 6 | 運用・リリース | ✅ 完了 | 21/24 | ✅ 合格 | `60_operations/review_phase06.md` |
| Phase 7 | ユーザーテスト | 🟡 計画完成・実施待ち | — | 実施後に判定 | `70_usertest/review_phase07.md` |

*D項目（API設計）はN/A除外で計算

---

## Phase 1 企画 — 主な指摘事項

**スコア: 23/25（✅ 合格）**

| 優先度 | 指摘 | 対応状況 |
|-------|------|---------|
| ✅ 対応済 | 収益モデル（先着1,000DL無料 → ¥590買い切り） | 完了 |
| ✅ 対応済 | KPI定義（4週継続率40%・初回記録完了率60%） | 完了 |
| ✅ 対応済 | ペルソナ詳細化（田中誠・32歳・ITコンサル） | 完了 |
| ✅ 対応済 | 市場規模の粗試算（TAM/SAM/SOM） | 完了 |
| 🟡 次フェーズ | 一次情報取得（ユーザーインタビュー） | フェーズ7で実施予定 |

---

## Phase 2 要件定義 — 主な指摘事項

**スコア: 19/23（✅ 合格）**

| 優先度 | 指摘 | 対応状況 |
|-------|------|---------|
| ✅ 対応済 | データ削除仕様（エンティティ・iCloud削除・削除後状態） | 2.8に追記 |
| ✅ 対応済 | 写真権限拒否時のエラーフロー（インラインメッセージ・設定誘導） | 2.9に追記 |
| ✅ 対応済 | iCloud未接続時の挙動（サイレント・ローカル継続） | 2.9に追記 |
| ✅ 対応済 | ペルソナ参照を要件定義書に追記 | 1.アプリ概要に田中誠参照を追加 |
| ✅ 対応済 | KPI計測要件の明示 | 3.5 KPI計測要件セクションを新設 |
| ✅ 対応済 | 通知文言方針の定義 | 2.10に敬語なし・絵文字なし・40文字以内を追記 |
| ✅ 対応済 | 曖昧表現の具体化 | ライフステージ名最大20文字・年齢0〜84歳に数値明記 |
| 🟡 許容済 | I/O記述形式・優先度付与・ユーザーストーリー形式 | 個人開発コンテキストで過剰要件として許容 |

---

## Phase 3 設計 — 主な指摘事項

**スコア: 22/27（✅ 合格・D項目N/A除外）**

| 優先度 | 指摘 | 対応状況 |
|-------|------|---------|
| ✅ 対応済 | エラー状態画面設計（E01写真権限拒否・E02 iCloud未接続） | screen_flow section 9に追記 |
| ✅ 対応済 | ショートカット失敗フォールバック（E03・7日判定バナー） | screen_flow section 9に追記 |
| ✅ 対応済 | TestFlightデプロイフロー記載 | architecture.md section 12に追記 |
| ✅ 対応済 | lifeWeekIndexインデックス明示 | db_design.md section 7に追記 |
| ✅ 対応済 | キャッシュ戦略の明示 | architecture.md section 11に追記 |
| ✅ 対応済 | SQLi/XSS対策のN/A明示 | architecture.md section 10に理由含めて追記 |
| 🟡 許容済 | 可用性アーキテクチャ・Admin画面・アダプティブ調整 | 個人アプリN/Aとして許容 |

---

## 各フェーズの成果物一覧

### Phase 1（企画）
- `10_planning/planning.md` — 企画書

### Phase 2（要件定義）
- `20_requirements/requirements.md` — 要件定義書（更新日: 2026/08/04）

### Phase 4（実装）— 作成済みファイル

| ファイル | 内容 |
|---------|------|
| `40_src/App/LifeInWeeksApp.swift` | アプリエントリー・RootView・TabView・オンボーディング制御 |
| `40_src/Models/UserProfile.swift` | SwiftDataモデル：ユーザープロフィール |
| `40_src/Models/LifeStage.swift` | SwiftDataモデル：ライフステージ（デフォルト10件含む） |
| `40_src/Models/Category.swift` | SwiftDataモデル：目標カテゴリー |
| `40_src/Models/WeekRecord.swift` | SwiftDataモデル：週次記録（lifeWeekIndex採用） |
| `40_src/Models/CategoryRating.swift` | SwiftDataモデル：カテゴリー別★評価 |
| `40_src/Repositories/RepositoryProtocol.swift` | 将来サーバー移行用抽象インターフェース |
| `40_src/Repositories/SwiftDataRepository.swift` | SwiftData実装・UserDefaultsキー定義 |
| `40_src/ViewModels/GridViewModel.swift` | グリッド画面VM・壁紙バナー判定 |
| `40_src/ViewModels/WeekDetailViewModel.swift` | 週詳細シートVM・★記録 |
| `40_src/ViewModels/StatsViewModel.swift` | 統計VM・ストリーク計算 |
| `40_src/Views/Grid/GridView.swift` | Canvas APIによる4,420点グリッド描画 |
| `40_src/Views/Grid/LifeStageBarView.swift` | ライフステージ左バー（Canvas） |
| `40_src/Views/WeekDetail/WeekDetailSheet.swift` | 週詳細ボトムシート・★評価UI |
| `40_src/Views/Stats/StatsSheet.swift` | 統計シート・Swift Charts |
| `40_src/Views/Onboarding/BirthDateInputView.swift` | O01 生年月日入力 |
| `40_src/Views/Onboarding/WallpaperGuideView.swift` | O02 壁紙ガイド（スキップ可） |
| `40_src/Views/Onboarding/CategorySetupView.swift` | O03 カテゴリー設定（スキップ可） |
| `40_src/Views/Settings/SettingsView.swift` | 設定画面・通知・全削除確認ダイアログ |
| `40_src/Utilities/WeekCalculator.swift` | lifeWeekIndex計算・座標変換 |
| `40_src/Utilities/ColorResolver.swift` | 丸の色判定ロジック・Color(hex:) |
| `40_src/Utilities/WallpaperRenderer.swift` | ImageRenderer壁紙生成・写真ライブラリ保存 |
| `40_src/AppIntents/GenerateWallpaperIntent.swift` | ショートカット公開アクション |

### Phase 3（設計）
- `30_design/ux/screen_flow.md` — 画面遷移・UX設計書 v2.0
- `30_design/system/architecture.md` — システムアーキテクチャ設計書
- `30_design/system/appintents_design.md` — AppIntents設計書
- `30_design/db/db_design.md` — DB設計書（lifeWeekIndex採用済み）
- `30_design/mockups/S01_grid_main.svg` — グリッド画面モックアップ
- `30_design/mockups/S03_statistics.svg` — 統計画面モックアップ
- `30_design/mockups/W01_wallpaper_image.svg` — 壁紙画像（390×820）
- `30_design/mockups/W02_homescreen_mockup.svg` — ホーム画面モックアップ
- `30_design/mockups/W03_lockscreen_mockup.svg` — ロック画面モックアップ
- `30_design/mockups/w03_tests/` — ロック画面年代別テスト（20代〜60代）

---

## Phase 4 着手前の必須チェックリスト

以下が全て完了してから実装を開始すること。

- [x] Phase1: 収益モデルの方針決定（先着1,000DL無料 → ¥590買い切り）
- [x] Phase1: KPI最低限定義（4週継続率40%・初回記録完了率60%）
- [x] Phase2: データ削除仕様の追記（requirements.md 2.8）
- [x] Phase2: 写真権限拒否時のエラーフロー定義（requirements.md 2.9）
- [x] Phase3: エラー状態画面の設計（screen_flow.md section 9 E01/E02）
- [x] Phase3: ショートカット失敗時フォールバック設計（screen_flow.md section 9 E03）

---

## 保留・将来対応事項

最終更新: 2026-08-10

| # | 内容 | 対応条件 | 参照 |
|---|------|---------|------|
| B-1 | 壁紙設定ガイドにショートカットApp実画面スクリーンショット（5枚）を追加 | 実機テスト時に撮影後、依頼 | `testflight-feedback_v4.md #7` |
| ~~B-2~~ | ~~`shortcuts://automations` URL スキームの動作確認と切り替え~~ | ✅ 動作確認済み・v1.4.1 実装済み | `testflight-feedback_v4.md #6` |

---

## 設計上の確定事項（実装時の重要メモ）

| 項目 | 確定内容 |
|------|---------|
| グリッド座標系 | 人生基準（左上=誕生週）。ISO 8601カレンダー週ではない |
| 現在週の計算 | `floor((today − birthDate).days / 7)` → lifeWeekIndex |
| DB主キー | WeekRecord: lifeWeekIndex（weekStartDateは廃止） |
| グリッド描画 | SwiftUI Canvas API（個別Circle()ビューは使わない） |
| 壁紙に左バーなし | 壁紙（W01/W02/W03）にライフステージバーを表示しない |
| 壁紙グリッド開始位置 | y=211（ロック画面最小時計の下）。ホーム画面はy=44から全面 |
| 現在週インジケーター | ゴールドリング（赤丸廃止）。行27、列10（1999/06/23生まれ基準） |
| タブ構成 | グリッド（S01）・統計（S03）・設定（S04）の3タブ |
| 下部統計バー | 廃止。人生消費率はS03統計画面に移動 |
