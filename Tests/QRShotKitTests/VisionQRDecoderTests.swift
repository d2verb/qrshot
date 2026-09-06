import CoreGraphics
import Testing

@testable import QRShotKit

@Suite("VisionQRDecoder")
struct VisionQRDecoderTests {
    @Test("ASCII の文字列が往復する")
    func decodesASCII() async throws {
        let decoded = try await VisionQRDecoder().decode(QRImageFixture.qr("hello world"))
        #expect(decoded?.payload == "hello world")
    }

    @Test("日本語の文字列が往復する")
    func decodesJapanese() async throws {
        let decoded = try await VisionQRDecoder().decode(QRImageFixture.qr("こんにちは世界"))
        #expect(decoded?.payload == "こんにちは世界")
    }

    @Test("URL が往復する")
    func decodesURL() async throws {
        let url = "https://example.com/path?query=1&other=2"
        let decoded = try await VisionQRDecoder().decode(QRImageFixture.qr(url))
        #expect(decoded?.payload == url)
    }

    @Test("QR が複数あるとき、面積が最大のものを採用する")
    func prefersLargestQR() async throws {
        let big = try QRImageFixture.qr("BIG", scale: 8)
        let small = try QRImageFixture.qr("SMALL", scale: 3)
        let canvas = try QRImageFixture.whiteCanvas(
            width: 400,
            height: 240,
            placing: [(big, CGPoint(x: 8, y: 8)), (small, CGPoint(x: 300, y: 150))]
        )

        let decoded = try await VisionQRDecoder().decode(canvas)

        #expect(decoded?.payload == "BIG")
        #expect(decoded?.detectedCount == 2)
    }

    @Test("QR が 1 つだけのとき detectedCount は 1")
    func reportsSingleDetection() async throws {
        let decoded = try await VisionQRDecoder().decode(QRImageFixture.qr("only one"))
        #expect(decoded?.detectedCount == 1)
    }

    @Test("QR の無い画像では nil を返す")
    func returnsNilForBlankImage() async throws {
        let blank = try QRImageFixture.whiteCanvas(width: 200, height: 200)
        let decoded = try await VisionQRDecoder().decode(blank)
        #expect(decoded == nil)
    }
}
