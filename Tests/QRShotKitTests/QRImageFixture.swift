import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

struct FixtureError: Error {
    let message: String
}

/// テスト内で QR 画像を組み立てる。フィクスチャ画像をリポジトリに置かずに済ませるため。
enum QRImageFixture {
    static func qr(_ text: String, scale: CGFloat = 8) throws -> CGImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else {
            throw FixtureError(message: "QR を生成できませんでした")
        }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let image = CIContext().createCGImage(scaled, from: scaled.extent) else {
            throw FixtureError(message: "CGImage に変換できませんでした")
        }
        return image
    }

    static func whiteCanvas(
        width: Int,
        height: Int,
        placing placements: [(image: CGImage, origin: CGPoint)] = []
    ) throws -> CGImage {
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw FixtureError(message: "CGContext を作れませんでした")
        }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        for placement in placements {
            context.draw(
                placement.image,
                in: CGRect(
                    x: placement.origin.x,
                    y: placement.origin.y,
                    width: CGFloat(placement.image.width),
                    height: CGFloat(placement.image.height)
                )
            )
        }
        guard let image = context.makeImage() else {
            throw FixtureError(message: "画像を書き出せませんでした")
        }
        return image
    }
}
