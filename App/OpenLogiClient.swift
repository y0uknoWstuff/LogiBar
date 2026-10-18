import AppKit
import Foundation

/// Talks to OpenLogi through its documented JSON automation API (`openlogi api …`,
/// schema_version 1). Never touches the hardware itself.
struct OpenLogiClient: Sendable {
    enum Failure: Error {
        case notInstalled
        case agentUnavailable
        case badOutput
    }

    private static let bundleID = "org.openlogi.openlogi"
    private static let supportedSchema = 1

    let executable: URL

    init() throws(Failure) {
        let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleID)
            ?? URL(fileURLWithPath: "/Applications/OpenLogi.app")
        let executable = app.appendingPathComponent("Contents/MacOS/openlogi")
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw .notInstalled
        }
        self.executable = executable
    }

    // MARK: - Commands

    struct DevicesData: Decodable {
        var inventory: String
        var devices: [RawDevice]
    }

    struct RawDevice: Decodable {
        var id: String?
        var name: String?
        var kind: String
        var online: Bool
        var battery: RawBattery?
    }

    struct RawBattery: Decodable {
        var percentage: Int?
        var level: String?
        var status: String?
    }

    struct DpiData: Decodable {
        var current: Int
    }

    struct SmartShiftData: Decodable {
        var mode: String
    }

    func devices() async throws -> DevicesData {
        try await run(["devices"])
    }

    func dpi(device id: String) async throws -> DpiData {
        try await run(["dpi", "--device", id])
    }

    func smartShift(device id: String) async throws -> SmartShiftData {
        try await run(["smartshift", "--device", id])
    }

    // MARK: - Envelope

    private struct Envelope<T: Decodable>: Decodable {
        var schema_version: Int
        var ok: Bool
        var data: T?
    }

    private struct Header: Decodable {
        var schema_version: Int
        var ok: Bool
    }

    private func run<T: Decodable>(_ arguments: [String]) async throws -> T {
        let output = try await Self.launch(executable, ["api"] + arguments)
        let header = try JSONDecoder().decode(Header.self, from: output)
        guard header.schema_version == Self.supportedSchema else { throw Failure.badOutput }
        guard header.ok else { throw Failure.agentUnavailable }
        guard let data = try JSONDecoder().decode(Envelope<T>.self, from: output).data else {
            throw Failure.badOutput
        }
        return data
    }

    private static func launch(_ executable: URL, _ arguments: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            // Read on a worker thread until EOF, so a large output can't fill the pipe and stall.
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                let stdout = Pipe()
                process.executableURL = executable
                process.arguments = arguments
                process.standardOutput = stdout
                process.standardError = FileHandle.nullDevice
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                let data = stdout.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                continuation.resume(returning: data)
            }
        }
    }
}
