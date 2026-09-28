# ビルド・リリース失敗ログ（4160 Life / LifeInWeeks）

## 環境情報
- Mac: MacBook Air (Retina, 13-inch, 2018) / Intel Core i5 1.6GHz
- macOS: 14.8.8 (Sonoma) ← このMacの上限。Sequoia(15)以上には上げられない
- Xcode: 16.2（iOS 18.2 SDK）← Xcode 26はインストール不可
- GitHub: https://github.com/axel45/life-shortness-visualizer
- Bundle ID: com.shogo.4160life

## 制約（必読）
- **Xcode 26はインストール不可**（macOS 15以上が必要だが、このMacはmacOS 14が上限）
- **Appleは2026年よりiOS 26 SDK必須**（Xcode 16.2では直接App Store提出不可）
- **手元のMacだけではApp Storeへのリリースは不可能**。クラウドビルドが必須。

---

## 失敗1: Xcode Product メニューから Xcode Cloud
- **操作**: Xcode → Product → Xcode Cloud → Create Workflow
- **結果**: メニュー項目自体が存在しない
- **試したこと**: Shared Scheme追加、GitHubアカウント連携 → 解消せず
- **再提案禁止**

## 失敗2: Window → Organizer から Xcode Cloud
- **操作**: Xcode → Window → Organizer → Xcode Cloud タブ
- **結果**: タブが存在しない
- **再提案禁止**

## 失敗3: App Store Connect「Xcodeを開く」
- **操作**: App Store Connect → Xcode Cloud タブ → 「Xcodeを開く」
- **結果**: Mac App StoreのXcode 26ページが開くだけ。インストール不可。
- **再提案禁止**

## 失敗4: Xcode 16.2から直接Archive & Upload
- **操作**: Product → Archive → Distribute App → App Store Connect → Upload
- **エラー**: `Validation failed - SDK version issue. This app was built with the iOS 18.2 SDK. All iOS and iPadOS apps must be built with the iOS 26 SDK or later.`
- **原因**: Appleが2026年よりiOS 26 SDK（Xcode 26以上）を必須化
- **再提案禁止**

---

---

## 成功: GitHub Actions（macos-26ランナー + Xcode 26.6）

v1.0.6以降で採用。タグプッシュ → 自動ビルド → TestFlightアップロードまで完全自動化。

### ビルド番号重複エラー（v1.0.8で発生）

- **エラー**: `The bundle version must be higher than the previously uploaded version: '1'`
- **原因**: `SupportingFiles/Info.plist` の `CFBundleVersion` が "1" 固定のまま。同じビルド番号を再アップロードしようとした。
- **修正**: `release.yml` に「Set Version」ステップを追加。PlistBuddyで `CFBundleVersion` を `${{ github.run_number }}` に自動設定。`CFBundleShortVersionString` はタグ名（v→削除）から取得。
- **v1.0.9から反映**。以後はrun番号が自動インクリメントされるため再発しない。
