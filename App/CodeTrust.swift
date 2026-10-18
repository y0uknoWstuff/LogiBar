import Foundation
import Security

/// Checks that a binary is OpenLogi as signed by its developer before LogiBar runs it.
/// LogiBar finds OpenLogi by bundle id, so without this any app claiming that id (say, one
/// dropped in Downloads) would be executed every poll.
enum CodeTrust {
    /// Developer ID Application: AprilNEA LLC, the OpenLogi release signer.
    private static let requirementText = """
        identifier "openlogi" and anchor apple generic \
        and certificate 1[field.1.2.840.113635.100.6.2.6] \
        and certificate leaf[subject.OU] = "8U3ZJ258K9"
        """

    private struct FileStamp: Equatable {
        var size: Int
        var modified: Date
        var inode: Int
    }

    private static let lock = NSLock()
    /// Validating hashes the whole binary, so a verdict is reused until the file changes.
    nonisolated(unsafe) private static var verdicts: [String: (FileStamp, Bool)] = [:]

    static func isTrustedOpenLogi(_ executable: URL) -> Bool {
        guard let stamp = stamp(of: executable) else { return false }
        let path = executable.path
        lock.lock()
        let cached = verdicts[path]
        lock.unlock()
        if let cached, cached.0 == stamp { return cached.1 }

        let trusted = validate(executable)
        lock.lock()
        verdicts[path] = (stamp, trusted)
        lock.unlock()
        return trusted
    }

    private static func validate(_ executable: URL) -> Bool {
        var code: SecStaticCode?
        var requirement: SecRequirement?
        guard SecStaticCodeCreateWithPath(executable as CFURL, [], &code) == errSecSuccess,
              let code,
              SecRequirementCreateWithString(requirementText as CFString, [], &requirement)
                == errSecSuccess,
              let requirement
        else { return false }
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate)
        return SecStaticCodeCheckValidity(code, flags, requirement) == errSecSuccess
    }

    private static func stamp(of url: URL) -> FileStamp? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int,
              let modified = attributes[.modificationDate] as? Date,
              let inode = attributes[.systemFileNumber] as? Int
        else { return nil }
        return FileStamp(size: size, modified: modified, inode: inode)
    }
}
