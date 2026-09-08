# TestFlight フィードバック v6

> このファイルで作業ログ・調査結果・対応状況を管理する。
> 議論が必要な項目のみチャットで行う。

---

## 対応状況サマリー

| # | 内容 | 優先度 | ステータス |
|---|------|--------|-----------|
| 1 | 記録画面の星反映が遅い | 🔴 高 | ✅ 実装完了 |
| 2 | オートメーション設定画面に説明文を追加 | 🟡 中 | ✅ 実装完了 |
| 3 | オートメーションの最新仕様調査 | 🟡 中 | ✅ 実装完了 |
| 4 | オートメーション設定画面に閉じるボタン追加 | 🟡 中 | ✅ 実装完了 |
| 5 | 他画面から記録画面遷移時に今週を表示 | 🔴 高 | ✅ 実装完了 |

---

## #1 記録画面の星反映が遅い

### フィードバック
記録自体は保存されているが、画面の更新がされない。記録画面を閉じて再度開くと最後に入力した星の数が反映される。星をタップしてから反映するまでの処理を最初から見直して。今の実装を説明して、改善案を何案か提案して。

### 現状調査（2026-09-07）

**関連ファイル**
- `40_src/Views/WeekDetail/WeekDetailSheet.swift`（行63-70）
- `40_src/ViewModels/WeekDetailViewModel.swift`（行45-68）

**現在の実装**
```swift
// WeekDetailSheet.swift（行66-69）
onStarTap: { stars in
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    Task { await viewModel.setStars(stars, for: category) }
}

// WeekDetailViewModel.swift（行45-68）
func setStars(_ stars: Int, for category: Category) async {
    // ... 既存保存ロジック ...
    try await repository.saveWeekRecord(record)
    weekRecord = try await repository.fetchWeekRecord(lifeWeekIndex: lifeWeekIndex)  // DB再取得
}
```

**根本原因**
- `@Observable` マクロは「プロパティ値の変更」を検知するが、**オブジェクト内部プロパティの変更は自動検知されない**
- `record.ratings` 内の `existing.stars = stars` を変更しても、`weekRecord` プロパティ自体の参照は変わらないため SwiftUI の再描画がトリガーされない
- DB 再取得（`fetchWeekRecord`）で初めて `weekRecord` が新しいオブジェクトに差し替えられるが、非同期遅延がある
- 画面を閉じて再度開くと `viewModel.load()` が走り DB から再取得するため正常に表示される

### 改善案

**案A: ローカルキャッシュで即座に UI 更新（推奨）**
- 星タップ → キャッシュに即反映 → DB保存は非同期 → UI は常にキャッシュ優先で参照
- メリット: タップした瞬間に星が即座に切り替わる。ユーザー体験が最良
- デメリット: エラー時のロールバック処理が必要。コードが若干複雑になる

**案B: オブジェクト再代入で @Observation を確実にトリガー**
- 保存後に `weekRecord = nil; weekRecord = fetchResult` と一度 nil 経由で差し替える
- メリット: 最小限の変更。既存ロジックをほぼ維持できる
- デメリット: nil の瞬間に UI が一瞬チラつく可能性。DB遅延は残る（タップ→即反映にはならない）

**案C: @Binding で子コンポーネントが直接更新**
- `CategoryRatingRow` に `@Binding var currentStars: Int` を渡し、タップ時に即 Binding を更新
- メリット: SwiftUI 推奨パターン
- デメリット: WeekDetailSheet の構造変更が必要。設計書との乖離が生じる

> 💬 **チャットで方針確認 → 案A で実装完了**

### 対応内容（2026-09-08）
`WeekDetailViewModel.swift` を修正。
- `cachedRatings: [UUID: Int]` プロパティを追加（`@Observable` で観測される通常プロパティ）
- `stars(for:)` でキャッシュ優先参照 → タップ瞬間にUI即更新
- `setStars()` の先頭でキャッシュ更新 → DB保存完了後にキャッシュ削除（DBから最新取得）
- エラー時はキャッシュをロールバック

---

## #2 オートメーション設定画面の説明文追加

### フィードバック
オートメーション設定画面では、時刻7:00を決めてから、繰り返し項目にて毎週 曜日を決め、その後確認後に実行かすぐに実行を選ぶことができる。その画面で何を選んでいいかを記載して。

### 対応内容（2026-09-08）
`WallpaperGuideView.swift` のステップ3を更新。
- 「時刻を7:00に設定」→「繰り返しで毎週・曜日を選択」→「すぐに実行を選択（確認なしで自動実行）」の3段階を説明文として追記
- ステップに `title` + `detail` の2段構成を導入

---

## #3 オートメーションの最新仕様調査

### フィードバック
オートメーション設定画面では「壁紙を生成して保存アクションを追加」とあるが、オートメーション画面では「月曜日、7:00に」4420 Life 選択：壁紙を更新 を選べるが、その後写真ライブラリから最新の画像を選択する操作にはならない。オートメーションの最新の仕様を調査して。

### 調査結果
`GenerateWallpaperIntent`（AppIntent）が壁紙生成から写真ライブラリ保存まで内部で自動実行する仕様のため、ショートカット側でユーザーが写真を手動選択する操作は発生しない。ユーザーが期待した「写真ライブラリから選択する」ステップは、旧来の別アプリ連携フロー（例: 写真アプリの「壁紙に設定」）と混同されたと考えられる。

### 対応内容（2026-09-08）
`WallpaperGuideView.swift` のステップ4を更新。
- 「壁紙を更新を選択。実行時にグリッド画像が自動生成・保存されます（写真の手動選択は不要です）」と明記

---

## #4 オートメーション設定画面に閉じるボタン追加

### フィードバック
オートメーション設定画面は下にスライドしたら閉じるが、右上に閉じるボタンをつけて閉じるようにして。

### 対応内容（2026-09-08）
`WallpaperGuideView.swift` に `@Environment(\.dismiss)` を追加。
- ZStack の右上に X ボタンをオーバーレイ配置
- シートとして表示時は `dismiss()` でシートを閉じる
- オンボーディングとして表示時は `dismiss()` が無害なため共通実装で対応

---

## #5 他画面から記録画面遷移時に今週を表示

### フィードバック
統計画面や設定画面から記録画面に遷移すると、先ほどまで選択していた週の記録入力になる。人生カレンダーに遷移した時と同じように、今週分の記録をするように修正して。

### 現状調査（2026-09-07）

**関連ファイル**
- `40_src/Views/Grid/GridView.swift`（行56-70）
- `40_src/ViewModels/GridViewModel.swift`（行55-64）

**現在の実装**
```swift
// GridViewModel.swift
func selectWeek(_ lifeWeekIndex: Int) {
    sheetLifeWeekIndex = lifeWeekIndex   // グリッドタップ時 → 選択週
    isWeekDetailPresented = true
}

func selectCurrentWeek() {
    sheetLifeWeekIndex = currentLifeWeekIndex  // FABタップ時 → 今週
    isWeekDetailPresented = true
}
```

**根本原因**
- 統計・設定はボトムシートとして表示され、閉じると GridView に戻る
- このとき `sheetLifeWeekIndex` はリセットされず、前回タップした週のまま
- 人生カレンダーからの遷移（グリッドの丸タップ or FAB）は毎回 `selectWeek()` か `selectCurrentWeek()` が呼ばれるので正常
- 統計・設定からタブバーの「記録」をタップすると、直前の `sheetLifeWeekIndex`（過去の週）が使われる

### 改善案

**案A: 統計・設定シートを閉じた時に今週にリセット（推奨・最小変更）**
- `isStatsPresented` と `isSettingsPresented` が false になった瞬間に `sheetLifeWeekIndex = currentLifeWeekIndex` を実行
- メリット: 変更箇所が GridView の `.onChange` に2行追加するだけ。リスク最小
- デメリット: 統計から特定の週を見ていた場合でもリセットされる（ただしフィードバックの要求は「今週にしてほしい」なので OK）

**案B: 記録タブボタンタップ時に強制リセット**
- タブバーの「記録」ボタン押下時のアクションで `sheetLifeWeekIndex = currentLifeWeekIndex` にリセット
- メリット: より明示的な制御
- デメリット: タブバーのカスタムボタン実装が必要（現在の構成確認が必要）

> 💬 **チャットで方針確認 → 案A で実装完了**

### 対応内容（2026-09-08）
`GridView.swift` に2点追加。
1. `.onAppear` — `userProfile` ロード済みの場合のみ `sheetLifeWeekIndex = currentLifeWeekIndex` にリセット（設定・統計タブから戻った時のタブ切り替えをカバー）
2. `.onChange(of: viewModel.isStatsPresented)` — Stats シートが閉じた時に `sheetLifeWeekIndex` を今週にリセット（ライフステージバータップ→Stats シート→閉じる のフローをカバー）

---

## 作業ログ

| 日時 | 作業内容 |
|------|---------|
| 2026-09-07 | フィードバックv6受領・ファイル構造化 |
| 2026-09-07 | #1・#5 ソースコード調査完了・改善案記載 |
| 2026-09-08 | #1/#2/#3/#4/#5 全件実装完了 → commit & push |
