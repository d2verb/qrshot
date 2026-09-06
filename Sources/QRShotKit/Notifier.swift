import Foundation

public enum NotificationOutcome: Equatable, Sendable {
    case success
    case failure

    public var message: String {
        switch self {
        case .success: "QRコードの読み込みに成功しました"
        case .failure: "QRコードが存在しないまたは読み取れない状態にあります"
        }
    }
}

/// 結果をユーザーに通知する。
public protocol Notifier {
    func notify(_ outcome: NotificationOutcome) throws
}

public enum NotifierError: Error, CustomStringConvertible {
    case launchFailed(String)

    public var description: String {
        switch self {
        case .launchFailed(let reason):
            return "terminal-notifier を実行できませんでした: \(reason)"
        }
    }
}

/// `terminal-notifier` を呼ぶ実装。
public struct TerminalNotifier: Notifier {
    public static let installHint = """
        terminal-notifier が見つかりません。次のコマンドでインストールしてください:
          brew install terminal-notifier
        """

    private let executableURL: URL

    public init(executableURL: URL) {
        self.executableURL = executableURL
    }

    /// PATH から terminal-notifier を探す。見つからなければ nil。
    public static func locate(
        path: String = ProcessInfo.processInfo.environment["PATH"] ?? ""
    ) -> TerminalNotifier? {
        for directory in path.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory))
                .appendingPathComponent("terminal-notifier")
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return TerminalNotifier(executableURL: candidate)
            }
        }
        return nil
    }

    public func notify(_ outcome: NotificationOutcome) throws {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["-title", "qrshot", "-message", outcome.message]
        do {
            try process.run()
        } catch {
            throw NotifierError.launchFailed(error.localizedDescription)
        }
        process.waitUntilExit()
    }
}
