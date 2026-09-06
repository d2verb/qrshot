# qrshot

macOS 用の CLI ツール。実行すると画面の領域選択が始まり、選択範囲に写っている QR コードをデコードしてクリップボードにコピーし、結果を通知で知らせる。

## 必要なもの

- macOS 15 以上
- [terminal-notifier](https://github.com/julienXX/terminal-notifier)

```bash
brew install terminal-notifier
```

`terminal-notifier` にフォールバックはない。無い場合、qrshot は領域選択を始める前に exit 2 で落ちる。範囲をドラッグしたあとで「通知できません」と言われることはない。

### 初回にハマりやすい 2 点

**通知の権限。** `brew install` した直後は通知がまだ許可されていないことがある。この状態だと QR の読み取り自体は成功していても exit 2 になる。「システム設定 > 通知 > terminal-notifier」で許可すること。なおクリップボードへのコピーは済んでいるので、`pbpaste` で中身は取り出せる。

**画面収録の権限。** 未許可だと `screencapture` が画像を作らずに終了する。qrshot はこれをキャンセルと区別できないため、何も起きずに exit 0 で終わる。何も起きない場合は「システム設定 > プライバシーとセキュリティ > 画面収録」を確認すること。許可が必要なのは qrshot 自体ではなく、qrshot を実行しているターミナルアプリ（Terminal.app、iTerm2 など）である。

## インストール

```bash
swift build -c release
cp .build/release/qrshot /usr/local/bin/
```

## 使い方

```bash
qrshot
```

十字カーソルが出るのでドラッグして範囲を選ぶ。スペースキーを押すとウィンドウ選択に切り替わり、Esc でキャンセルできる。

- 読み取れた場合: 中身がクリップボードにコピーされ、「QRコードの読み込みに成功しました」の通知が出る
- QR が無い、または読み取れない場合: 「QRコードが存在しないまたは読み取れない状態にあります」の通知が出る
- 複数写っていた場合: 一番大きく写っているものを採用し、stderr に注記を出す

引数は `--help`（`-h`）と `--version` のみ。この 2 つは他の引数より優先されるため、`qrshot --bogus --help` は usage を表示して exit 0 になる。

## 終了コード

| exit | 意味 |
|---|---|
| 0 | 読み取り成功、またはキャンセル |
| 1 | QR が無い、または読み取れなかった |
| 2 | 環境エラー（`terminal-notifier` が無い/失敗した、`screencapture` が起動できない、クリップボードに書けない、不明な引数） |

どの経路がどのコードになるかの詳細は、設計書の「終了コードと出口の一覧」を参照。
`docs/superpowers/specs/2026-09-06-qrshot-design.md`

## 開発

[AGENTS.md](AGENTS.md) を参照。
