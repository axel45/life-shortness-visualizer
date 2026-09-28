# DB設計書

作成日: 2026年8月2日
ステータス: pending-approval

---

## 1. 概要

- **採用技術**：SwiftData + CloudKit（iCloud自動同期）
- **将来移行**：Repository抽象化層により自前サーバーへの差し替え可能
- **同期方式**：CloudKitのデフォルト競合解決（タイムスタンプ優先）

---

## 2. エンティティ一覧

| エンティティ | 説明 | 件数目安 |
|------------|------|---------|
| UserProfile | ユーザープロフィール | 1件固定 |
| LifeStage | ライフステージ定義 | 最大20件程度 |
| Category | 目標カテゴリー | 最大5件 |
| WeekRecord | 週次記録 | 最大4,160件（80年分） |
| CategoryRating | カテゴリー別★評価 | WeekRecord × Category数 |

---

## 3. エンティティ詳細

### UserProfile

| カラム名 | 型 | 必須 | 説明 |
|---------|-----|------|------|
| id | UUID | ✅ | 主キー |
| birthDate | Date | ✅ | 生年月日（オンボーディングで入力） |
| lifeExpectancy | Int | ✅ | 想定寿命（デフォルト：85） |
| createdAt | Date | ✅ | 作成日時 |
| updatedAt | Date | ✅ | 更新日時 |

- 端末に1件のみ存在する
- `birthDate` からグリッドの全週を計算する

---

### LifeStage

| カラム名 | 型 | 必須 | 説明 |
|---------|-----|------|------|
| id | UUID | ✅ | 主キー |
| name | String | ✅ | ステージ名（例：小学校） |
| startAge | Int | ✅ | 開始年齢（歳） |
| endAge | Int | ✅ | 終了年齢（歳）※含まない |
| colorHex | String | ✅ | カラーコード（例：#FFD700） |
| order | Int | ✅ | 表示順（小さい順に上から表示） |
| createdAt | Date | ✅ | 作成日時 |
| updatedAt | Date | ✅ | 更新日時 |

**バリデーション**
- `startAge < endAge` であること
- ステージ同士の年齢が重複しないこと
- `colorHex` は有効な16進数カラーコードであること

**デフォルトデータ（初回起動時に自動挿入）**

| order | name | startAge | endAge | colorHex |
|-------|------|----------|--------|----------|
| 1 | 未就学児 | 0 | 6 | #8B9BB4 |
| 2 | 小学校 | 6 | 12 | #7A8FA6 |
| 3 | 中学 | 12 | 15 | #7A87A6 |
| 4 | 高校 | 15 | 18 | #8B87A6 |
| 5 | 大学 | 18 | 22 | #8B7FA6 |
| 6 | 社会人なりたて | 22 | 27 | #D4A017 |
| 7 | プロジェクトリーダー（仮） | 27 | 32 | #FFD700 |
| 8 | マネージャー（仮） | 32 | 40 | #DAA520 |
| 9 | マネージャー以降のキャリア | 40 | 65 | #8B7355 |
| 10 | 老後 | 65 | 85 | #696969 |

---

### Category

| カラム名 | 型 | 必須 | 説明 |
|---------|-----|------|------|
| id | UUID | ✅ | 主キー |
| name | String | ✅ | カテゴリー名（例：運動） |
| order | Int | ✅ | 表示順 |
| isActive | Bool | ✅ | 有効フラグ（削除は論理削除） |
| createdAt | Date | ✅ | 作成日時 |
| updatedAt | Date | ✅ | 更新日時 |

**バリデーション**
- `isActive = true` のカテゴリーが最大5件まで
- `name` は空文字不可・最大20文字

**デフォルトデータ（オンボーディングスキップ時に自動挿入）**

| order | name |
|-------|------|
| 1 | 運動 |
| 2 | 食事 |
| 3 | 睡眠 |
| 4 | 仕事 |

---

### WeekRecord

| カラム名 | 型 | 必須 | 説明 |
|---------|-----|------|------|
| id | UUID | ✅ | 主キー |
| lifeWeekIndex | Int | ✅ | 誕生週を 0 とした人生通し週番号（0 〜 lifeExpectancy×52−1） |
| createdAt | Date | ✅ | 作成日時 |
| updatedAt | Date | ✅ | 更新日時 |
| ratings | [CategoryRating] | ✅ | カテゴリー別評価（リレーション） |

**バリデーション**
- `lifeWeekIndex` は `0 ≦ lifeWeekIndex < lifeExpectancy × 52` であること
- 同じ `lifeWeekIndex` のレコードは 1 件のみ（ユニーク制約）

**グリッド座標への変換**
```swift
let row = lifeWeekIndex / 52   // 何年目か（0始まり）
let col = lifeWeekIndex % 52   // その年の何週目か（0始まり）
```

**表示日付範囲の計算（CalendarHelper）**
```swift
// weekStartDate は DB に保存せず、表示時に都度計算する
let weekStart = birthDate.addingTimeInterval(Double(lifeWeekIndex) * 7 * 86400)
let weekEnd   = weekStart.addingTimeInterval(6 * 86400)
// 例）1999/06/23生まれ、lifeWeekIndex=0 → "1999年6月23日 〜 6月29日"
```

**現在週の特定**
```swift
let lifeWeekIndex = Int(Date().timeIntervalSince(birthDate) / (7 * 86400))
```

**補足**
- WeekRecord が存在しない週はグレー表示（未記録扱い）
- 記録時に初めてレコードを作成する（全週分を事前生成しない）
- ISO 8601 カレンダー週とは一致しない。カレンダー上の月曜始まりではなく、誕生日を起点とした 7 日間が 1 週となる

---

### CategoryRating

| カラム名 | 型 | 必須 | 説明 |
|---------|-----|------|------|
| id | UUID | ✅ | 主キー |
| weekRecordId | UUID | ✅ | WeekRecord への外部キー |
| categoryId | UUID | ✅ | Category への外部キー |
| stars | Int | ✅ | 評価（0=未評価、1〜5=評価済み） |
| createdAt | Date | ✅ | 作成日時 |
| updatedAt | Date | ✅ | 更新日時 |

**バリデーション**
- `stars` は 0〜5 の整数のみ
- 同じ `weekRecordId` + `categoryId` の組み合わせは1件のみ（ユニーク制約）

---

## 4. エンティティ関連図

```
UserProfile (1)
    │
    └── LifeStage (多) ※UserProfileに紐づくが実質グローバル設定

Category (多)
    │
    └── CategoryRating (多)
          │
WeekRecord (1) ──── CategoryRating (多)
```

---

## 5. 丸の色決定ロジック（DB観点）

```
WeekRecord が存在しない
  → グレー

WeekRecord が存在する場合
  → 紐づく CategoryRating（stars > 0）を取得
  → 評価済みのものが0件 → グレー
  → 全件 stars = 5 → 金色
  → 平均 stars ≧ 4.0 → 銀色
  → 平均 stars ≧ 3.0 → 白
  → 平均 stars < 3.0 → グレー
```

---

## 6. データ量見積もり

| エンティティ | 最大件数 | 1件あたりサイズ（概算） | 合計 |
|------------|---------|----------------------|------|
| UserProfile | 1 | 100B | 100B |
| LifeStage | 20 | 200B | 4KB |
| Category | 5 | 100B | 500B |
| WeekRecord | 4,160 | 100B | 442KB |
| CategoryRating | 22,100（4,160×5） | 80B | 1.8MB |

**合計：約2.3MB** → iCloudの無料枠（1GB）に対して問題なし

---

## 7. インデックス設計

SwiftDataはCloudKitと連携するため、明示的なDDLインデックス定義はないが、SwiftDataのクエリパターンに合わせて以下の検索効率を確保する。

| エンティティ | 対象カラム | インデックス種別 | 目的 |
|------------|----------|---------------|------|
| WeekRecord | `lifeWeekIndex` | ユニーク制約 | 重複レコード防止。グリッド描画時の週検索に使用 |
| CategoryRating | `weekRecordId` + `categoryId` | 複合ユニーク制約 | 同週×同カテゴリーの重複防止 |
| Category | `isActive` | — | `@Query` で `isActive == true` フィルタリング（件数最大5件のため専用インデックス不要） |

**パーティション戦略**
最大データ量は約2.3MB（セクション6参照）。SwiftData + CloudKit構成でデータ量がフルに蓄積されても1GBのiCloud無料枠の0.2%以下。パーティション・アーカイブは不要。

---

## 8. マイグレーション方針

- SwiftDataのスキーマバージョン管理（`VersionedSchema`）を使用
- カラム追加はデフォルト値付きで後方互換を保つ
- 破壊的変更（カラム削除・型変更）は `MigrationStage` で明示的に対応
