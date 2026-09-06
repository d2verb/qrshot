import CoreGraphics
import Foundation
import ImageIO

/// 画面の領域選択を行い、キャプチャした画像を返す。
public protocol ScreenCapturer {
    /// ユーザーが選択をキャンセルした場合は nil を返す。
    func capture() throws -> CGImage?
}

public enum ScreenCaptureError: Error, CustomStringConvertible {
    case launchFailed(String)
    case unreadableImage

    public var description: String {
        switch self {
        case .launchFailed(let reason):
            return "screencapture を実行できませんでした: \(reason)"
        case .unreadableImage:
            return "スクリーンショットを画像として読み込めませんでした"
        }
    }
}

/// `screencapture -i` で領域選択を行う実装。
public struct InteractiveScreenCapturer: ScreenCapturer {
    public init() {}

    public func capture() throws -> CGImage? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("qrshot-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", url.path]
        do {
            try process.run()
        } catch {
            throw ScreenCaptureError.launchFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        // Esc でキャンセルしたときの終了コードは macOS のバージョンで揺れるため、
        // 出力ファイルの有無で判定する。
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ScreenCaptureError.unreadableImage
        }
        return image
    }
}
