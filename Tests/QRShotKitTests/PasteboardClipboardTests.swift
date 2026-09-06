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
}
