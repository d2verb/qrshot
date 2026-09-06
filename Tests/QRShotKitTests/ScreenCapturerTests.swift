import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import QRShotKit

@Suite("InteractiveScreenCapturer")
struct ScreenCapturerTests {
    // capture() は一時ファイルを screencapture -i で生成させられないため、
    // ここでは QRImageFixture で作った CGImage を自前で PNG に書き出してから
    // loadImage(at:) に渡す。
    private func writePNG(_ image: CGImage, to url: URL) throws {
        guard
            let destination = CGImageDestinationCreateWithURL(
                url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else {
            throw FixtureError(message: "画像の書き出し先を作れませんでした")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError(message: "PNG の書き出しに失敗しました")
        }
    }

    // ここでのポイントは削除の順序: loadImage(at:) の呼び出しが終わった後、
    // デコードを試みる「前」にファイルを消している。CGImageSourceCreateWithURL を
    // 使う旧実装だと CGImage は画素をファイルから遅延読み込みするため、この時点で
    // 中身を読めなくなる。先に Data へ読み切る実装であれば、ファイルが無くなっても
    // デコードは成功するはずで、それこそがこのテストが固定したい退行防止の要点。
    @Test("読み込み後にファイルを消してもデコードできる")
    func decodesAfterFileIsDeleted() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("qrshot-test-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }

        let qrImage = try QRImageFixture.qr("regression test")
        try writePNG(qrImage, to: url)

        let loaded = try InteractiveScreenCapturer.loadImage(at: url)

        try FileManager.default.removeItem(at: url)
        // 削除がデコードの「前」に起きていること自体がこのテストの本体。
        // この行を消して並べ替えると、テストは名前とコメントを保ったまま
        // 何も検証しなくなる。
        #expect(!FileManager.default.fileExists(atPath: url.path))

        let decoded = try await VisionQRDecoder().decode(loaded)
        #expect(decoded?.payload == "regression test")
    }

    @Test("画像ではないファイルは unreadableImage を投げる")
    func throwsForNonImageFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("qrshot-test-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("これは画像ではありません".utf8).write(to: url)

        #expect(throws: ScreenCaptureError.unreadableImage) {
            try InteractiveScreenCapturer.loadImage(at: url)
        }
    }

    // screencapture が書き込み途中で死ぬと空ファイルが残りうる。
    // ちなみに「途中まで書かれた PNG」はここに来ない。ImageIO は欠損行を
    // 埋めた原寸画像を返してしまうので、その場合はデコード側の nil 経路
    //（QR が見つからない）で処理されることになる。
    @Test("空ファイルは unreadableImage を投げる")
    func throwsForEmptyFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("qrshot-test-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data().write(to: url)

        #expect(throws: ScreenCaptureError.unreadableImage) {
            try InteractiveScreenCapturer.loadImage(at: url)
        }
    }

    @Test("存在しないパスは unreadableImage を投げる")
    func throwsForMissingFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("qrshot-test-does-not-exist-\(UUID().uuidString).png")

        #expect(throws: ScreenCaptureError.unreadableImage) {
            try InteractiveScreenCapturer.loadImage(at: url)
        }
    }
}
