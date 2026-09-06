/// 領域選択からクリップボードへのコピーまでの流れを組み立てる。
public struct QRShot {
    public enum Outcome: Equatable, Sendable {
        case copied(DecodedQR)
        case notFound
        case cancelled
    }

    private let capturer: any ScreenCapturer
    private let decoder: any QRDecoder
    private let clipboard: any Clipboard
    private let notifier: any Notifier

    public init(
        capturer: any ScreenCapturer,
        decoder: any QRDecoder,
        clipboard: any Clipboard,
        notifier: any Notifier
    ) {
        self.capturer = capturer
        self.decoder = decoder
        self.clipboard = clipboard
        self.notifier = notifier
    }

    public func run() async throws -> Outcome {
        guard let image = try capturer.capture() else { return .cancelled }
        guard let decoded = try await decoder.decode(image) else {
            try notifier.notify(.failure)
            return .notFound
        }
        try clipboard.copy(decoded.payload)
        try notifier.notify(.success)
        return .copied(decoded)
    }
}
