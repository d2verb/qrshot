import Testing

@testable import QRShotKit

@Suite("QRShot")
struct QRShotTests {
    private func makeQRShot(
        capturer: StubScreenCapturer,
        decoder: StubQRDecoder,
        clipboard: SpyClipboard,
        notifier: SpyNotifier
    ) -> QRShot {
        QRShot(capturer: capturer, decoder: decoder, clipboard: clipboard, notifier: notifier)
    }

    @Test("キャンセル時はクリップボードにも通知にも触らない")
    func cancelTouchesNothing() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let qrshot = makeQRShot(
            capturer: StubScreenCapturer(image: nil),
            decoder: StubQRDecoder(result: DecodedQR(payload: "unused", detectedCount: 1)),
            clipboard: clipboard,
            notifier: notifier
        )

        let outcome = try await qrshot.run()

        #expect(outcome == .cancelled)
        #expect(clipboard.copied.isEmpty)
        #expect(notifier.notified.isEmpty)
    }

    @Test("読み取り成功時はコピー 1 回と成功通知 1 回")
    func successCopiesAndNotifies() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let decoded = DecodedQR(payload: "https://example.com", detectedCount: 1)
        let qrshot = makeQRShot(
            capturer: StubScreenCapturer(image: try QRImageFixture.qr("unused")),
            decoder: StubQRDecoder(result: decoded),
            clipboard: clipboard,
            notifier: notifier
        )

        let outcome = try await qrshot.run()

        #expect(outcome == .copied(decoded))
        #expect(clipboard.copied == ["https://example.com"])
        #expect(notifier.notified == [.success])
    }

    @Test("読み取り失敗時はコピーせず失敗通知だけ出す")
    func failureNotifiesWithoutCopying() async throws {
        let clipboard = SpyClipboard()
        let notifier = SpyNotifier()
        let qrshot = makeQRShot(
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
        let qrshot = makeQRShot(
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
}
