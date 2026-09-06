import AppKit

/// 文字列をクリップボードへ書き込む。
public protocol Clipboard {
    func copy(_ text: String) throws
}

public enum ClipboardError: Error, Equatable, CustomStringConvertible {
    case writeFailed

    public var description: String {
        switch self {
        case .writeFailed: "クリップボードに書き込めませんでした"
        }
    }
}

/// `NSPasteboard` による実装。テストでは一時ペーストボードを注入する。
public struct PasteboardClipboard: Clipboard {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func copy(_ text: String) throws {
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw ClipboardError.writeFailed
        }
    }
}
