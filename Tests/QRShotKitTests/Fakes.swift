import CoreGraphics
import Foundation

@testable import QRShotKit

struct FakeError: Error, Equatable {
    let message: String
}

final class StubScreenCapturer: ScreenCapturer {
    private let image: CGImage?
    private let error: (any Error)?

    init(image: CGImage?, error: (any Error)? = nil) {
        self.image = image
        self.error = error
    }

    func capture() throws -> CGImage? {
        if let error { throw error }
        return image
    }
}

final class StubQRDecoder: QRDecoder {
    private let result: DecodedQR?

    init(result: DecodedQR?) {
        self.result = result
    }

    func decode(_ image: CGImage) async throws -> DecodedQR? {
        result
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

    func notify(_ outcome: NotificationOutcome) throws {
        notified.append(outcome)
    }
}
