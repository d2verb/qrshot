import CoreGraphics
import Vision

/// デコードに成功した QR コード 1 件と、同じ画像から見つかった総数。
public struct DecodedQR: Equatable, Sendable {
    public let payload: String
    public let detectedCount: Int

    public init(payload: String, detectedCount: Int) {
        self.payload = payload
        self.detectedCount = detectedCount
    }
}

/// 画像から QR コードを読み取る。
public protocol QRDecoder {
    /// QR が無い、または文字列として読み取れない場合は nil を返す。
    func decode(_ image: CGImage) async throws -> DecodedQR?
}

/// Vision による実装。面積が最大の QR を優先して採用する。
public struct VisionQRDecoder: QRDecoder {
    public init() {}

    public func decode(_ image: CGImage) async throws -> DecodedQR? {
        var request = DetectBarcodesRequest()
        request.symbologies = [.qr]
        let observations = try await request.perform(on: image)

        let largestFirst = observations.sorted { area(of: $0) > area(of: $1) }
        guard let payload = largestFirst.lazy.compactMap(\.payloadString).first else {
            return nil
        }
        return DecodedQR(payload: payload, detectedCount: observations.count)
    }

    private func area(of observation: BarcodeObservation) -> Double {
        observation.boundingBox.width * observation.boundingBox.height
    }
}
