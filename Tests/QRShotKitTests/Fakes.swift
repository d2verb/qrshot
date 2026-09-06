import CoreGraphics

@testable import QRShotKit

struct FakeError: Error {
    let message: String
}

// Fake のスタイル分け:
// - `Stub*` と `Spy*` はどちらも呼び出された事実を記録する（`callCount` など）。
// - 違いは失敗をいつ設定するか: `Stub*` は構築時に固定する（`init(..., error:)`）、
//   `Spy*` は構築後に `var failure: (any Error)?` を書き換えて差し込む。

final class StubScreenCapturer: ScreenCapturer {
    private let image: CGImage?
    private let error: (any Error)?
    private(set) var callCount = 0

    init(image: CGImage? = nil, error: (any Error)? = nil) {
        self.image = image
        self.error = error
    }

    func capture() throws -> CGImage? {
        callCount += 1
        if let error { throw error }
        return image
    }
}

final class StubQRDecoder: QRDecoder {
    private let result: DecodedQR?
    private let error: (any Error)?
    private(set) var callCount = 0

    init(result: DecodedQR?, error: (any Error)? = nil) {
        self.result = result
        self.error = error
    }

    func decode(_ image: CGImage) async throws -> DecodedQR? {
        callCount += 1
        if let error { throw error }
        return result
    }
}

final class SpyClipboard: Clipboard {
    private(set) var copied: [String] = []
    var failure: (any Error)?

    func copy(_ text: String) throws {
        if let failure { throw failure }
        copied.append(text)
    }
}

final class SpyNotifier: Notifier {
    private(set) var notified: [NotificationOutcome] = []
    var failure: (any Error)?

    func notify(_ outcome: NotificationOutcome) throws {
        if let failure { throw failure }
        notified.append(outcome)
    }
}
