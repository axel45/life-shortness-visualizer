# テスト計画書

プロジェクト: Life in Weeks（人生の短さ可視化アプリ）
作成日: 2026年8月5日
対象バージョン: 1.0.0

---

## 1. テスト対象スコープ

### 対象（MustHave）
| 機能 | 要件参照 |
|------|---------|
| オンボーディング（O01〜O03） | requirements.md 2.6 |
| グリッド表示・丸の色判定 | requirements.md 2.2 |
| 週次目標管理（★記録） | requirements.md 2.3 |
| 統計・ストリーク | requirements.md 2.4 |
| 壁紙生成（AppIntent） | requirements.md 2.5 |
| 設定（プロフィール・カテゴリー・ライフステージ） | requirements.md 2.7 |
| データ削除 | requirements.md 2.8 |
| 写真権限エラーフロー | requirements.md 2.9 |
| プッシュ通知 | requirements.md 2.10 |
| iCloud同期 | requirements.md 3.3 |

### 対象外
- API設計（外部APIなし）
- 管理画面（個人アプリN/A）
- SQLi/XSSテスト（SwiftData ORM・ネイティブアプリN/A）

---

## 2. テスト種別と方針

| 種別 | 方針 | ツール |
|------|------|-------|
| 単体テスト | WeekCalculator・ColorResolverのロジックを自動テスト | Swift Testing（`swift test`）|
| 統合テスト | Repository + SwiftData の読み書きをシミュレーターで確認 | Xcode UI Test（手動） |
| E2Eテスト | オンボーディング〜グリッド表示〜★記録の主要フローを手動実行 | 実機 / Simulator |
| パフォーマンステスト | グリッド4,160点の描画が60fps維持されるか | Xcode Instruments |
| エラー系テスト | 写真権限拒否・iCloud未接続の挙動を手動確認 | Simulator設定変更 |

---

## 3. テスト環境

| 項目 | 内容 |
|------|------|
| 実機 | iPhone（iOS 17以上）が望ましい |
| Simulator | iPhone 16 / iOS 18 |
| ビルド構成 | Debug（com.shogo.lifeinweeks.debug） |
| 自動テスト | `swift test`（macOS上でコアロジックのみ実行） |

---

## 4. テスト完了の定義

以下を全て満たした時点でPhase5完了とする：

- [ ] 自動テスト: 全件 PASS（現在 17/17）
- [ ] E2Eテスト: 主要フロー（オンボーディング〜★記録〜統計確認）が1周完了
- [ ] Critical バグ: 0件
- [ ] High バグ: 全件修正済み
- [ ] パフォーマンス: グリッド描画でフレームドロップなし（Instruments確認）

---

## 5. スケジュール

| フェーズ | 内容 | 担当 |
|---------|------|------|
| 自動テスト | `swift test` で即時実行 | Claude（完了済み） |
| Simulatorビルド確認 | `xcodebuild build` で確認 | Claude（完了済み） |
| E2Eテスト | Xcodeで実機/Simulator実行・主要フロー確認 | Shogo |
| パフォーマンス確認 | Instruments → Time Profiler でCanvas描画確認 | Shogo |
