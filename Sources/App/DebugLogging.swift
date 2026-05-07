#if DEBUG
import Foundation
import Darwin
import CMUXDebugLog

@inline(__always)
func cmuxDebugLog(_ message: @autoclosure () -> String) {
    CMUXDebugLog.logDebugEvent(message())
}

enum CmuxLifecycleExitTracker {
    private static let markerVersion = 1
    private static var isInstalled = false
    private static var markerURL: URL?

    static func install(environment: [String: String] = ProcessInfo.processInfo.environment) {
        guard !isInstalled else { return }
        isInstalled = true

        let url = lifecycleMarkerURL(environment: environment)
        markerURL = url
        logPreviousExitIfNeeded(markerURL: url)

        writeMarker(
            to: url,
            fields: launchMarkerFields(environment: environment).merging([
                "cleanExit": false,
                "state": "running"
            ]) { _, new in new }
        )

        cmuxDebugLog(
            "lifecycle.launch pid=\(ProcessInfo.processInfo.processIdentifier) " +
            "bundle=\(Bundle.main.bundleIdentifier ?? "unknown") " +
            "app=\(Bundle.main.bundlePath) " +
            "log=\(environment["CMUX_DEBUG_LOG"] ?? "default")"
        )
    }

    static func recordTerminationIntent(reason: String) {
        updateMarker([
            "terminationIntent": reason,
            "terminationIntentAt": isoTimestamp(),
            "state": "terminating"
        ])
        cmuxDebugLog("lifecycle.terminate.intent reason=\(reason) pid=\(ProcessInfo.processInfo.processIdentifier)")
    }

    static func recordTerminationCancelled(reason: String) {
        updateMarker([
            "terminationIntent": "",
            "terminationCancelledReason": reason,
            "terminationCancelledAt": isoTimestamp(),
            "state": "running"
        ])
        cmuxDebugLog("lifecycle.terminate.cancelled reason=\(reason) pid=\(ProcessInfo.processInfo.processIdentifier)")
    }

    static func markCleanExit(reason: String) {
        updateMarker([
            "cleanExit": true,
            "state": "cleanExit",
            "terminationReason": reason,
            "terminatedAt": isoTimestamp()
        ])
        cmuxDebugLog("lifecycle.cleanExit reason=\(reason) pid=\(ProcessInfo.processInfo.processIdentifier)")
    }

    private static func logPreviousExitIfNeeded(markerURL: URL) {
        guard
            let marker = readMarker(from: markerURL),
            let cleanExit = marker["cleanExit"] as? Bool,
            cleanExit == false
        else { return }

        let previousPid = marker["pid"] as? Int ?? -1
        let pidAlive = previousPid > 0 && Darwin.kill(pid_t(previousPid), 0) == 0
        let startedAt = marker["startedAt"] as? String ?? "unknown"
        let intent = marker["terminationIntent"] as? String ?? ""
        let appPath = marker["appPath"] as? String ?? "unknown"
        let debugLog = marker["debugLog"] as? String ?? "unknown"

        cmuxDebugLog(
            "lifecycle.previousExit kind=unclean " +
            "pid=\(previousPid) pidAlive=\(pidAlive ? 1 : 0) " +
            "startedAt=\(startedAt) intent=\(intent.isEmpty ? "none" : intent) " +
            "app=\(appPath) previousLog=\(debugLog)"
        )
    }

    private static func updateMarker(_ updates: [String: Any]) {
        guard let url = markerURL else { return }
        var marker = readMarker(from: url) ?? [:]
        for (key, value) in updates {
            marker[key] = value
        }
        writeMarker(to: url, fields: marker)
    }

    private static func lifecycleMarkerURL(environment: [String: String]) -> URL {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown.bundle"
        let tag = environment["CMUX_TAG"].flatMap { $0.isEmpty ? nil : $0 } ?? "default"
        let filenameSafeBundleID = bundleID.replacingOccurrences(of: "/", with: "_")
        let filenameSafeTag = tag.replacingOccurrences(of: "/", with: "_")
        return applicationSupportDirectory()
            .appendingPathComponent("lifecycle-\(filenameSafeBundleID)-\(filenameSafeTag).json")
    }

    private static func launchMarkerFields(environment: [String: String]) -> [String: Any] {
        [
            "version": markerVersion,
            "pid": Int(ProcessInfo.processInfo.processIdentifier),
            "startedAt": isoTimestamp(),
            "bundleID": Bundle.main.bundleIdentifier ?? "",
            "bundleName": Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "",
            "displayName": Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "",
            "bundleVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
            "executablePath": Bundle.main.executablePath ?? "",
            "appPath": Bundle.main.bundlePath,
            "socketPath": environment["CMUX_SOCKET_PATH"] ?? "",
            "debugLog": environment["CMUX_DEBUG_LOG"] ?? "",
            "repoRoot": environment["CMUXTERM_REPO_ROOT"] ?? "",
            "tag": environment["CMUX_TAG"] ?? ""
        ]
    }

    private static func applicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let directory = base.appendingPathComponent("cmux", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func readMarker(from url: URL) -> [String: Any]? {
        guard
            let data = try? Data(contentsOf: url),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return object
    }

    private static func writeMarker(to url: URL, fields: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(fields),
              let data = try? JSONSerialization.data(withJSONObject: fields, options: [.prettyPrinted, .sortedKeys])
        else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func isoTimestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
#endif
