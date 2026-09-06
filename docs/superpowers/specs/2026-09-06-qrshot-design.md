# qrshot 設計

作成日: 2026-09-06

## 概要

`qrshot` は macOS 用の CLI ツール。実行すると画面の領域選択が始まり、選択範囲に写っている QR コードをデコードしてクリップボードにコピーし、結果を通知で知らせる。

## スコープ

対象:

- 引数なしの単一コマンド `qrshot`（`--help` / `--version` のみ受け付ける）
- 領域選択によるスクリーンショット取得
- QR コードのデコードとクリップボードへのコピー
- 成功・失敗の通知

対象外:

- QR 以外のバーコード（EAN、Code128 など）
- 画像ファイルを引数に取る入力経路
- 出力先を切り替えるフラグ（`--print`、`--no-clipboard` など）
- 自前の領域選択オーバーレイ UI

## 動作

1. `terminal-notifier` が PATH にあるか確認する。無ければ stderr にインストール案内を出して exit 2。キャプチャは開始しない。
2. `screencapture -i <一時PNG>` を実行する。矩形選択から始まり、スペースキーでウィンドウ選択に切り替わる。シャッター音は無効化しない。
3. 一時 PNG が生成されなければキャンセルとみなし、何もせず exit 0。
4. 生成された画像を Vision の `DetectBarcodesRequest`（`symbologies = [.qr]`）でデコードする。
5. デコードできた文字列をクリップボードにコピーし、成功通知を出して exit 0。
6. デコードできなければ失敗通知を出して exit 1。
7. どの経路でも一時 PNG は削除する。

### キャンセル判定

Esc でキャンセルしたときの `screencapture` の終了コードは macOS のバージョンによって揺れる実績があるため、**終了コードではなく出力ファイルの有無で判定する**。

### 複数検出時

検出結果を `boundingBox` の面積降順に並べ、`payloadStringValue` が取れる最初のものを採用する。領域を自分で囲んでいる以上、狙いはその中で一番大きく写っている QR である可能性が高い。2 個以上検出した場合は stderr に一行注記を出す。この件数は読み取れなかった QR も含むため、注記は「読み取れたうち一番大きいものを使った」と書く。

`payloadStringValue` が `nil` のもの（バイナリペイロードの QR）は文字列化できないため読み取り不能として扱い、次の候補へ進む。

`boundingBox` は 4 隅から計算される軸平行の外接矩形であり、QR 本体の四角形の面積そのものではない。大きく傾いた QR では、真の面積が小さいほうが外接矩形では勝つことがある。画面上の QR はほぼ軸平行なので実害はないと判断し、四角形の面積を計算し直すことはしない。

### 通知

`terminal-notifier -title qrshot -message "..."` を `Process` で引数配列のまま渡す。シェルを経由しないため、デコード結果に何が入っていてもエスケープ事故が起きない。

| 結果 | メッセージ |
|---|---|
| 成功 | QRコードの読み込みに成功しました |
| 失敗 | QRコードが存在しないまたは読み取れない状態にあります |

成功通知にデコード結果そのものは載せない。QR の中身が通知センターの履歴に残るのを避けるため。

### 終了コードと出口の一覧

| 状況 | 通知 | stderr | exit |
|---|---|---|---|
| QR 読み取り成功 | 成功メッセージ | — | 0 |
| QR 複数検出 → 最大を採用 | 成功メッセージ | `N 個検出したので、読み取れたうち一番大きいものを使いました` | 0 |
| Esc でキャンセル | なし | — | 0 |
| QR が無い / 読めない | 失敗メッセージ | — | 1 |
| `terminal-notifier` が無い | 出せない | インストール案内 | 2 |
| `screencapture` が起動できない | なし | 起動失敗の内容 | 2 |
| クリップボード書き込み失敗 | なし | 失敗の内容 | 2 |

### 既知の制限

画面収録権限が未許可のとき、macOS 側が許可ダイアログを出して `screencapture` はファイルを作らずに終了する。この状態はキャンセルと区別がつかず、静かに exit 0 になる。緩衝材として `screencapture` の stderr を捨てずに親の stderr へ流し、権限まわりのメッセージがユーザーの目に入るようにする。

## アーキテクチャ

```
Package.swift
Sources/
  QRShotKit/
    QRShot.swift            オーケストレータ
    ScreenCapturer.swift    protocol + InteractiveScreenCapturer
    QRDecoder.swift         protocol + VisionQRDecoder
    Clipboard.swift         protocol + PasteboardClipboard
    Notifier.swift          protocol + TerminalNotifier
  qrshot/
    main.swift              組み立てと exit code
Tests/
  QRShotKitTests/
```

実行ファイルターゲットはテストターゲットから import できないため、ロジックはすべて `QRShotKit` に置く。`qrshot` ターゲットは各実装を組み立てて `QRShot` に渡し、返ってきた結果を exit code に変換するだけにとどめる。

### 各コンポーネントの責務

| 型 | 役割 | 依存 |
|---|---|---|
| `ScreenCapturer` | 領域選択を行い、画像を返す。キャンセルなら `nil` | — |
| `InteractiveScreenCapturer` | `screencapture -i` を叩く実装 | Foundation |
| `QRDecoder` | 画像を受け取り、QR の文字列を返す | — |
| `VisionQRDecoder` | Vision による実装 | Vision |
| `Clipboard` | 文字列をクリップボードへ書く | — |
| `PasteboardClipboard` | `NSPasteboard` による実装。テスト用に pasteboard を注入できる | AppKit |
| `Notifier` | 成功・失敗を通知する | — |
| `TerminalNotifier` | `terminal-notifier` を叩く実装 | Foundation |
| `QRShot` | 上 4 つを注入され、動作の流れを組み立てて結果を返す | 上記プロトコルのみ |

`QRShot` は具体実装を一切知らない。プロトコルだけに依存するため、fake を差し替えて経路をテストできる。

## テスト

### 自動テストする

- `VisionQRDecoder`: `CIFilter.qrCodeGenerator` でテスト内に QR 画像を生成してデコードする。フィクスチャ画像をリポジトリに置かずに済む
  - ASCII / 日本語 / URL が往復すること
  - 大小 2 つの QR を 1 枚に合成し、大きいほうの中身が返ること
  - QR の無い単色画像で `nil` が返ること
  - バイナリペイロードの QR（`payloadStringValue` が `nil`）だけの画像で `nil` が返ること
  - バイナリペイロードの QR のほうが大きくても、読み取れる次の候補が採用されること
- `QRShot`: fake の Capturer / Decoder / Clipboard / Notifier を注入して経路を確認
  - キャンセル時、クリップボードにも通知にも一切触らない
  - 成功時、コピーが 1 回・成功通知が 1 回
  - デコード失敗時、コピーは 0 回・失敗通知が 1 回
- `InteractiveScreenCapturer.loadImage`: PNG を読み込んだ後に元ファイルを消しても、その `CGImage` からデコードできること
  - `CGImageSourceCreateWithURL` が返す `CGImage` は画素をファイルから遅延読み込みする。`capture()` は一時ファイルを `defer` で消してから画像を返すため、素朴に書くと QR が写っていても必ず読み取り失敗になる。先に `Data` へ読み切ってファイルの寿命から切り離す
- `PasteboardClipboard`: `NSPasteboard.withUniqueName()` を注入し、ユーザーの実クリップボードを壊さずに書き込みと読み返しを検証する
  - 前の内容の別形式（HTML など）が残らないこと。`clearContents` を省くと、リッチテキストをコピーした直後の実行で古い内容が貼られてしまう

### テスト実行上の注意

`NSPasteboard` は並行アクセスに耐えない。名前の違うペーストボードを使っていても AppKit 内部の共有状態でレースし、`stringForType:` が `objc_msgSend` で不正ポインタ参照を起こしてテストプロセスごと落ちる（スイート全体の並行実行で約 10%、実測）。`PasteboardClipboard` のスイートには `.serialized` を付けて直列化する。製品コードは `NSPasteboard.general` を 1 回触るだけなので、これはテスト固有の問題であり製品の欠陥ではない。

### 自動テストしない

- `InteractiveScreenCapturer.capture` と `TerminalNotifier.notify`: どちらも人間の操作か通知センターの目視が要る。README に手動確認手順を残す（読み込み部分の `loadImage` は分離してテストする）
- 傾き・低コントラスト・小さい QR の検出精度: Vision の担当範囲であり、他人の実装を測ることになるため

## 依存

- 外部 Swift パッケージ: なし
- 実行時依存: `terminal-notifier`（`brew install terminal-notifier`）。無い場合はフォールバックせず exit 2 で落ちる
- プラットフォーム: macOS 15 以上（Swift ネイティブの `DetectBarcodesRequest` が macOS 15 で導入されたため）
- テストフレームワーク: Swift Testing（`import Testing`）

## 検討したが採用しなかった案

- **ScreenCaptureKit + 自前オーバーレイ**: 見た目を完全に制御できるが実装量とテストコストが大きく、`screencapture -i` がタダで提供する挙動（スペースでウィンドウ選択、Esc でキャンセル、Retina スケール対応）を自前で再実装することになる
- **`.app` バンドル + `UNUserNotificationCenter`**: 「qrshot」名義の正規な通知が出せるが、Info.plist・ad-hoc 署名・バンドル組み立てスクリプトが必要になり、CLI ツールとしてのビルドと配布が一段複雑になる
- **CoreImage の `CIDetector(QRCode)`**: 古い API で、傾き・低コントラスト・小さめの QR に明確に弱い。スクリーンショットという荒い入力を扱う以上 Vision のほうが素直
- **旧 Vision API（`VNDetectBarcodesRequest` + `VNImageRequestHandler`）**: macOS 14 を対象にできる。macOS 26 SDK でも非推奨警告は出ないが、コードが手続き的になる。macOS 15 を切り捨てる実害がないため、async/await の新 API を選んだ
- **全部 `main.swift` に直書き**: 200 行程度で済むが、テストが実質手動確認のみになる
