import AppKit
import Testing

@testable import QRShotKit

@Suite("PasteboardClipboard")
struct PasteboardClipboardTests {
    @Test("書き込んだ文字列が読み返せる")
    func writesString() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }

        try PasteboardClipboard(pasteboard: pasteboard).copy("コピーされる文字列")

        #expect(pasteboard.string(forType: .string) == "コピーされる文字列")
    }

    @Test("2 回書き込むと後のものだけが残る")
    func replacesPreviousContents() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        let clipboard = PasteboardClipboard(pasteboard: pasteboard)

        try clipboard.copy("さいしょ")
        try clipboard.copy("あと")

        #expect(pasteboard.string(forType: .string) == "あと")
    }

    // 上の 2 件は setString しか固定しない（clearContents を消しても通る）。
    // clearContents が守っているのは、前の内容の別形式が残ってしまうケース。
    // リッチテキストをコピーした直後に qrshot を使うと、Mail や Notes は
    // 古い HTML のほうを優先して貼り付けてしまう。
    @Test("先にあった別形式の内容は残らない")
    func clearsStaleRepresentations() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.clearContents()
        _ = pasteboard.setString("<b>ふるい HTML</b>", forType: .html)

        try PasteboardClipboard(pasteboard: pasteboard).copy("あたらしい")

        #expect(pasteboard.string(forType: .string) == "あたらしい")
        #expect(pasteboard.string(forType: .html) == nil)
    }
}
