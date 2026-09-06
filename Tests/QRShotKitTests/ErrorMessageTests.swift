import Testing

@testable import QRShotKit

// main.swift は `catch { fail("\(error)") }` としており、error は `any Error` の
// ままユーザー向けのメッセージへ変換される。これは各エラー enum が
// CustomStringConvertible に適合していることに依存しているが、その依存は
// コンパイラでは守られない。適合を外してもビルドは通り、既存のテストも
// 全部通ってしまう。このスイートは `any Error` として補間したときに
// 人間が読める日本語文になることを固定し、適合が外れて生の enum 表現
//（例: `exitedNonZero(1)`）がユーザーに見えてしまう退行を検知する。
@Suite("CustomStringConvertible")
struct ErrorMessageTests {
    @Test("ScreenCaptureError は any Error として補間しても読める文言になる")
    func screenCaptureErrorDescribesReadably() {
        let launchFailed: any Error = ScreenCaptureError.launchFailed("権限がありません")
        #expect("\(launchFailed)".contains("screencapture を実行できませんでした"))

        let unreadableImage: any Error = ScreenCaptureError.unreadableImage
        #expect("\(unreadableImage)".contains("画像として読み込めませんでした"))
    }

    @Test("ClipboardError は any Error として補間しても読める文言になる")
    func clipboardErrorDescribesReadably() {
        let writeFailed: any Error = ClipboardError.writeFailed
        #expect("\(writeFailed)".contains("クリップボードに書き込めませんでした"))
    }

    @Test("NotifierError は any Error として補間しても読める文言になる")
    func notifierErrorDescribesReadably() {
        let launchFailed: any Error = NotifierError.launchFailed("PATH が壊れています")
        #expect("\(launchFailed)".contains("terminal-notifier を実行できませんでした"))

        let exitedNonZero: any Error = NotifierError.exitedNonZero(17)
        let message = "\(exitedNonZero)"
        #expect(message.contains("終了コード"))
        #expect(message.contains("17"))
    }
}
