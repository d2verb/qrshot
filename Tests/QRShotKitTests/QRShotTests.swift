import Testing

@testable import QRShotKit

@Suite("QRShot")
struct QRShotTests {
    @Test("キャンセル時はクリップボードにも通知にも触らない")
    func cancelTouchesNothing() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let decoder = StubQRDecoder(result: DecodedQR(payload: "unused", detectedCount: 1))
        let qrshot = QRShot(
            capturer: StubScreenCapturer(image: nil),
            decoder: decoder,
            clipboard: clipboard,
            notifier: notifier
        )

        let outcome = try await qrshot.run()

        #expect(outcome == .cancelled)
        #expect(clipboard.copied.isEmpty)
        #expect(notifier.notified.isEmpty)
        #expect(decoder.callCount == 0)
    }

    @Test("読み取り成功時はコピー 1 回と成功通知 1 回")
    func successCopiesAndNotifies() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let decoded = DecodedQR(payload: "https://example.com", detectedCount: 3)
        let capturer = StubScreenCapturer(image: try QRImageFixture.qr("unused"))
        let decoder = StubQRDecoder(result: decoded)
        let qrshot = QRShot(
            capturer: capturer,
            decoder: decoder,
            clipboard: clipboard,
            notifier: notifier
        )

        let outcome = try await qrshot.run()

        #expect(outcome == .copied(decoded))
        #expect(clipboard.copied == ["https://example.com"])
        #expect(notifier.notified == [.success])
        #expect(capturer.callCount == 1)
        #expect(decoder.callCount == 1)
    }

    @Test("読み取り失敗時はコピーせず失敗通知だけ出す")
    func failureNotifiesWithoutCopying() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let qrshot = QRShot(
            capturer: StubScreenCapturer(image: try QRImageFixture.qr("unused")),
            decoder: StubQRDecoder(result: nil),
            clipboard: clipboard,
            notifier: notifier
        )

        let outcome = try await qrshot.run()

        #expect(outcome == .notFound)
        #expect(clipboard.copied.isEmpty)
        #expect(notifier.notified == [.failure])
    }

    @Test("クリップボード書き込みが失敗したら成功通知を出さない")
    func clipboardFailureSuppressesSuccessNotification() async throws {
        let clipboard = SpyClipboard()
        clipboard.failure = FakeError(message: "書き込み不可")
        let notifier = SpyNotifier()
        let qrshot = QRShot(
            capturer: StubScreenCapturer(image: try QRImageFixture.qr("unused")),
            decoder: StubQRDecoder(result: DecodedQR(payload: "text", detectedCount: 1)),
            clipboard: clipboard,
            notifier: notifier
        )

        await #expect(throws: FakeError.self) {
            try await qrshot.run()
        }
        #expect(notifier.notified.isEmpty)
    }

    @Test("キャプチャの失敗はキャンセルに丸めず伝播する")
    func captureErrorPropagates() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let qrshot = QRShot(
            capturer: StubScreenCapturer(image: nil, error: FakeError(message: "起動失敗")),
            decoder: StubQRDecoder(result: DecodedQR(payload: "unused", detectedCount: 1)),
            clipboard: clipboard,
            notifier: notifier
        )

        await #expect(throws: FakeError.self) { try await qrshot.run() }
        #expect(clipboard.copied.isEmpty)
        #expect(notifier.notified.isEmpty)
    }

    @Test("デコードの失敗は「見つからない」に丸めず伝播する")
    func decodeErrorPropagates() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let qrshot = QRShot(
            capturer: StubScreenCapturer(image: try QRImageFixture.qr("unused")),
            decoder: StubQRDecoder(result: nil, error: FakeError(message: "Vision エラー")),
            clipboard: clipboard,
            notifier: notifier
        )

        await #expect(throws: FakeError.self) { try await qrshot.run() }
        #expect(clipboard.copied.isEmpty)
        #expect(notifier.notified.isEmpty)
    }

    @Test("成功通知の失敗時もクリップボードへの書き込みは残る")
    func successNotifierFailureStillCopiesToClipboard() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        notifier.failure = FakeError(message: "通知失敗")
        let qrshot = QRShot(
            capturer: StubScreenCapturer(image: try QRImageFixture.qr("unused")),
            decoder: StubQRDecoder(result: DecodedQR(payload: "https://example.com", detectedCount: 1)),
            clipboard: clipboard,
            notifier: notifier
        )

        await #expect(throws: FakeError.self) { try await qrshot.run() }
        #expect(clipboard.copied == ["https://example.com"])
    }

    @Test("失敗通知の失敗も伝播する")
    func failureNotifierFailurePropagates() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        notifier.failure = FakeError(message: "通知失敗")
        let qrshot = QRShot(
            capturer: StubScreenCapturer(image: try QRImageFixture.qr("unused")),
            decoder: StubQRDecoder(result: nil),
            clipboard: clipboard,
            notifier: notifier
        )

        await #expect(throws: FakeError.self) { try await qrshot.run() }
        #expect(clipboard.copied.isEmpty)
    }
}
