import Foundation
import QRShotKit

let version = "0.1.0"
let usage = """
    qrshot - 画面の領域を選択して、写っている QR コードをクリップボードへコピーします

    使い方:
      qrshot                領域選択を開始する
      qrshot --help, -h     このヘルプを表示する
      qrshot --version      バージョンを表示する

    実行には terminal-notifier が必要です:
      brew install terminal-notifier
    """

func printToStandardError(_ message: String) {
    fputs(message + "\n", stderr)
}

func fail(_ message: String) -> Never {
    printToStandardError(message)
    exit(2)
}

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.contains("--help") || arguments.contains("-h") {
    print(usage)
    exit(0)
}

if arguments.contains("--version") {
    print("qrshot \(version)")
    exit(0)
}

guard arguments.isEmpty else {
    fail("不明な引数: \(arguments.joined(separator: " "))\n\n\(usage)")
}

guard let notifier = TerminalNotifier.locate() else {
    fail(TerminalNotifier.installHint)
}

let qrshot = QRShot(
    capturer: InteractiveScreenCapturer(),
    decoder: VisionQRDecoder(),
    clipboard: PasteboardClipboard(),
    notifier: notifier
)

do {
    switch try await qrshot.run() {
    case .cancelled:
        exit(0)
    case .copied(let decoded):
        if decoded.detectedCount > 1 {
            printToStandardError(
                "QR コードを \(decoded.detectedCount) 個検出したので、読み取れたうち一番大きいものを使いました")
        }
        exit(0)
    case .notFound:
        exit(1)
    }
} catch {
    fail("\(error)")
}
