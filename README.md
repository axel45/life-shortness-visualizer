# Life in Weeks — ソースコード

## Xcodeプロジェクト作成手順

### 前提
- Xcode 15以上
- iOS 17以上のシミュレーターまたは実機
- Apple Developerアカウント（iCloud/CloudKit使用のため）

### 手順

1. **新規プロジェクト作成**
   - Xcode > File > New > Project
   - iOS > App を選択
   - Product Name: `LifeInWeeks`
   - Bundle Identifier: `com.shogo.lifeinweeks`
   - Interface: SwiftUI
   - Storage: SwiftData

2. **ファイルの追加**
   - `40_src/` 配下の全ディレクトリ・ファイルをXcodeプロジェクトにドラッグ
   - 自動生成された `ContentView.swift` と `Item.swift` は削除

3. **Capabilities設定**
   - Target > Signing & Capabilities
   - `+ Capability` → `iCloud` を追加
   - CloudKit にチェック。Container: `iCloud.com.shogo.lifeinweeks`
   - `Push Notifications` を追加

4. **Info.plist設定**
   ```xml
   <key>NSPhotoLibraryAddUsageDescription</key>
   <string>人生グリッドの壁紙を写真ライブラリに保存するために使用します</string>
   ```

5. **ビルド確認**
   - Command + B でビルド
   - エラーがなければ実機またはシミュレーターで実行

### 環境変数・シークレット
なし（APIキー不使用・外部サービス連携なし）

### Debug / Release 環境の違い
| 設定 | Debug | Release |
|------|-------|---------|
| Bundle ID | `com.shogo.lifeinweeks.debug` | `com.shogo.lifeinweeks` |
| CloudKit Container | 同一（テストデータに注意） | 本番 |

> 現時点では`#if DEBUG`分岐は未実装。TestFlight準備時に追加予定。
