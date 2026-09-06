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

        return try Self.loadImage(at: url)
    }

    /// PNG ファイルを読み込んで `CGImage` にする。
    ///
    /// `CGImageSourceCreateWithURL` が返す `CGImage` は画素をファイルから遅延読み込みするため、
    /// 元ファイルを消すと中身が読めなくなる。capture() は一時ファイルを defer で消してから
    /// 画像を返すので、先に `Data` へ読み切ってから image source を作り、
    /// ファイルの寿命から切り離す。
    static func loadImage(at url: URL) throws -> CGImage {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ScreenCaptureError.unreadableImage
        }
        return image
    }
}
