import Foundation
import Testing

@testable import QRShotKit

@Suite("TerminalNotifier.locate")
struct TerminalNotifierLocateTests {
    /// PATH の 1 要素として使える一時ディレクトリを作る。
    /// `executable` が true のとき、その中に実行可能な terminal-notifier を置く。
    private func makeDirectory(containingExecutable executable: Bool) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("qrshot-locate-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if executable {
            let binary = directory.appendingPathComponent("terminal-notifier")
            try Data("#!/bin/sh\n".utf8).write(to: binary)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: binary.path)
        }
        return directory
    }

    @Test("PATH 上に実行可能な terminal-notifier があれば見つかる")
    func findsExecutableOnPath() throws {
        let directory = try makeDirectory(containingExecutable: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(TerminalNotifier.locate(path: directory.path) != nil)
    }

    @Test("PATH 上に無ければ nil")
    func returnsNilWhenAbsent() throws {
        let directory = try makeDirectory(containingExecutable: false)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(TerminalNotifier.locate(path: directory.path) == nil)
    }

    @Test("PATH が空なら nil")
    func returnsNilForEmptyPath() {
        #expect(TerminalNotifier.locate(path: "") == nil)
    }

    @Test("PATH の後ろのディレクトリにあっても見つかる")
    func searchesEveryPathEntry() throws {
        let empty = try makeDirectory(containingExecutable: false)
        let populated = try makeDirectory(containingExecutable: true)
        defer {
            try? FileManager.default.removeItem(at: empty)
            try? FileManager.default.removeItem(at: populated)
        }

        #expect(TerminalNotifier.locate(path: "\(empty.path):\(populated.path)") != nil)
    }

    @Test("実行権限のないファイルは無視する")
    func ignoresNonExecutableFile() throws {
        let directory = try makeDirectory(containingExecutable: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let binary = directory.appendingPathComponent("terminal-notifier")
        try Data("#!/bin/sh\n".utf8).write(to: binary)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: binary.path)

        #expect(TerminalNotifier.locate(path: directory.path) == nil)
    }

    @Test("同名のディレクトリは無視する")
    func ignoresDirectoryNamedLikeTheExecutable() throws {
        let directory = try makeDirectory(containingExecutable: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("terminal-notifier"),
            withIntermediateDirectories: true)

        #expect(TerminalNotifier.locate(path: directory.path) == nil)
    }
}
