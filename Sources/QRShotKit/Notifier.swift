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
    case exitedNonZero(Int32)

    public var description: String {
        switch self {
        case .launchFailed(let reason):
            return "terminal-notifier を実行できませんでした: \(reason)"
        case .exitedNonZero(let status):
            return "terminal-notifier が終了コード \(status) で失敗しました"
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
        // `split` は空要素（"/a::/b" や末尾の ":"）を落とすため、POSIX と違って
        // 空の PATH 要素をカレントディレクトリとして扱わない。これは意図的で、
        // 外部バイナリをカレントディレクトリから黙って拾うのは危険なため。
        for directory in path.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory))
                .appendingPathComponent("terminal-notifier")
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(
                atPath: candidate.path, isDirectory: &isDirectory)
            // `isExecutableFile` だけだと 0755 のディレクトリにも true を返し、
            // 同名のディレクトリが事前チェックを通過してしまう。
            guard exists, !isDirectory.boolValue else { continue }
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
        guard process.terminationStatus == 0 else {
            throw NotifierError.exitedNonZero(process.terminationStatus)
        }
    }
}
