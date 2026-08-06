# フェーズ4 UXレビュー結果

レビュー実施日: 2026年8月6日（第1回）
対象: `40_src/` 配下の全Viewファイル（実装コードとscreen_flow.md v2.0の照合）

---

## A. オンボーディングフロー

- [○] O01 生年月日 + 想定寿命を1画面で収集 → BirthDateInputViewに両方実装済み。残り週数リアルタイム表示あり
- [○] O00 スプラッシュ画面 → SplashView実装済み。TimelineView + Canvasで468個の丸が左上から右下へ波状にフェードイン。テキスト・ボタンも順番にフェードイン。「始める」で次へ進む（今回実装）
- [○] O01.5 グリッド生成アニメーション（ピーク体験） → GridGenerationView実装済み。TimelineView+Canvasでユーザーの実グリッドを過去週から順番にスキャン描画。現在週でゴールドリング表示・notificationFeedback(.success)。Reduce Motion対応（今回実装）
- [○] O02（WallpaperGuide）・O03（CategorySetup）のスキップ設計 → 「あとで設定する」「スキップ」で次へ進める

**A: 4/4**

---

## B. グリッド画面（S01）

- [○] 4,420個の丸をCanvasで描画 → DotGridCanvasによる高パフォーマンス実装
- [○] 現在週のゴールドリング → selectedLifeWeekIndexとcurrentLifeWeekIndexで正しく描画
- [○] 週タップ→WeekDetailSheet表示 → SpatialTapGestureで座標→lifeWeekIndexの逆算が実装済み
- [○] FABボタンで今週の記録シートを開く → selectCurrentWeek()で今週を選択して遷移
- [○] FABボタンの記録済み状態表示 → isCurrentWeekRecordedでpencil/plusアイコン・white/yellowカラー切り替えを実装（今回修正）
- [○] 壁紙バナーの表示・非表示制御 → 月曜日判定・7日経過・非表示フラグで制御済み
- [○] 壁紙バナーの「今すぐ更新する」ボタン → generateWallpaper()実装済み（前回修正）
- [○] 初回グリッド表示の空状態誘導メッセージ → weekRecordMapが空の場合にグリッド中央付近に「FABボタンから今週の記録をつけよう」オーバーレイを表示（今回実装）

**B: 8/8**

---

## C. 週詳細シート（S02）

- [○] 週の日付範囲・年齢の表示 → WeekCalculator経由で正確に表示
- [○] カテゴリーごとのstar評価UI → CategoryRatingRowで1〜5の★タップ、同一tap でリセット
- [○] 44pt以上のタップ領域 → `.frame(minWidth: 44, minHeight: 44)` で準拠
- [○] ハプティクス（.light）→ 今回修正で追加。各星タップ時にUIImpactFeedbackGenerator(.light)
- [○] エラーアラート表示 → 今回修正で追加。errorMessageをアラートで表示
- [○] カテゴリー未設定時の空状態 → 「カテゴリーが未設定です・設定から追加してください」を表示
- [!] 丸カラープレビュー・目標勾配メッセージが未実装 → 「あと1★で金になります」等の動機付けUIなし
  > **解消不要理由**: MVPスコープ外。コアの記録機能は動作する。エンゲージメント改善としてv1.1で検討。

**C: 6/7**

---

## D. 統計シート（S03）

- [○] 人生消費率のProgressBar表示 → lifeConsumedPercentをProgressViewで表示
- [○] カテゴリー別LineMarkグラフ（Swift Charts）→ 週次評価の折れ線グラフ実装済み
- [○] ストリーク（連続★3以上週数）表示 → calculateStreakで現在週から遡って集計
- [○] 記録なし時の空状態 → 「記録がまだありません」をframe(height:80)内に表示
- [○] エラーアラート表示 → 今回修正で追加。StatsViewModelにerrorMessageを追加
- [!] ストリークの視覚的強調が弱い → 「🔥42週連続達成中」の大きな表示が設計書にあるが、caption sizeの小さい表示のみ
  > **解消不要理由**: ストリーク数値の表示は実装済み。UIの強調度はv1.1の改善項目。機能的欠缺ではない。
- [!] ライフステージ別達成率サマリーが未実装 → 「小学校 ████████░░ 78%」形式のプログレスバーなし
  > **解消不要理由**: MVPスコープ外。カテゴリー別グラフで代替可能。v1.1での実装を検討。

**D: 5/7**

---

## E. 設定画面（S04）

- [○] 生年月日の表示 → プロフィールセクションでText表示（変更はDatePickerで実装済み）
- [○] 想定寿命のStepper変更 → Stepperで60〜120歳の範囲を変更可能
- [○] カテゴリー削除（swipe to delete）→ onDelete実装済み
- [○] 通知のToggle + 許可リクエスト → UNUserNotificationCenterで権限要求済み
- [○] 壁紙ガイドへのアクセス → WallpaperGuideView再表示リンクあり
- [○] データ全削除（確認ダイアログ） → 「この操作は元に戻せません」の確認後に削除
- [○] ライフステージ編集UI → 各ステージ行をタップするとモーダルシートで名前・開始年齢・終了年齢・ColorPickerを編集可能。保存時に重複バリデーション実施（今回実装）

**E: 7/7**

---

## F. エラー・フィードバック設計

- [○] GridViewのエラーアラート → viewModel.errorMessageをアラートで表示済み
- [○] WeekDetailSheetのエラーアラート → 今回修正で追加
- [○] StatsSheetのエラーアラート → 今回修正で追加（StatsViewModel.errorMessageも追加）
- [○] 写真権限エラーのアラート → WallpaperError.photoPermissionDeniedをerrorMessageに変換してアラート表示
- [○] 星評価のハプティクス → 今回修正で追加（UIImpactFeedbackGenerator(.light)）
- [○] 保存完了時の成功ハプティクス → WeekDetailViewModel.setStars()の保存完了後にUINotificationFeedbackGenerator().notificationOccurred(.success)を追加（今回実装）

**F: 6/6**

---

## 総合判定

| カテゴリ | 合格数/総数 | 判定 |
|---------|-----------|------|
| A. オンボーディング | 4/4 | ✅ 全項目合格 |
| B. グリッド画面 | 8/8 | ✅ 全項目合格 |
| C. 週詳細シート | 6/7 | ✅ 概ね良好 |
| D. 統計シート | 5/7 | ✅ 概ね良好 |
| E. 設定画面 | 7/7 | ✅ 全項目合格 |
| F. エラー・フィードバック | 6/6 | ✅ 全項目合格 |
| **合計** | **36/39** | |

**判定結果: ✅ 合格**（残存[!]3件はC・D各セクション内で解消不要理由を明示済み）

---

## 今回修正した項目（このレビューで解消）

| 修正 | 内容 |
|------|------|
| FABの記録済み状態表示 | `isCurrentWeekRecorded` でpencil/plusアイコン・white/yellowカラー切り替え |
| WeekDetailSheetのエラーアラート | `viewModel.errorMessage` を `.alert` で表示 |
| 星評価のハプティクス | `UIImpactFeedbackGenerator(.light).impactOccurred()` を星タップ時に呼び出し |
| StatsSheetのエラーアラート | `StatsViewModel.errorMessage` 追加 + `.alert` で表示 |
| StatsViewModelのprintデバッグ → errorMessage | エラーをprint捨てからUI表示に変更 |

## 残存[!]の全一覧（解消不要理由あり）

| ID | 項目 | 理由 |
|----|------|------|
| C-7 | 丸カラープレビュー・目標勾配メッセージなし | MVPスコープ外・コア記録機能は動作・v1.1 |
| D-6 | ストリーク強調度が弱い | 機能は実装済み・デザイン改善はv1.1 |
| D-7 | ライフステージ別達成率サマリーなし | MVPスコープ外・カテゴリー別グラフで代替可能・v1.1 |

## 今回解消した[!]項目

| ID | 項目 | 解消方法 |
|----|------|---------|
| A-3 | O01.5グリッド生成アニメーション | GridGenerationView実装（今回） |
| B-8 | 初回グリッド空状態演出 | weekRecordMap空時のオーバーレイ実装（今回） |
| E-7 | ライフステージ編集UI | 編集シート実装（名前・年齢・色・バリデーション）（今回） |
| F-6 | 保存完了ハプティクス | setStars()完了後にnotificationFeedback(.success)（今回） |
