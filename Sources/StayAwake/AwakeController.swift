import Foundation

/// Drives both sleep-prevention mechanisms macOS needs behind a single on/off toggle:
/// `caffeinate` for idle/display sleep (no privileges needed), and `pmset disablesleep`
/// for lid-close sleep (requires one admin prompt, since it's a system-wide setting).
final class AwakeController {
    private(set) var isOn = false
    private var caffeinateProcess: Process?

    /// Resolves a leftover `disablesleep 1` from a previous crash/force-quit back to 0.
    /// Called once at launch, before the user has touched the toggle.
    func resyncAfterCrashIfNeeded() {
        guard currentDisableSleepValue() == "1" else { return }
        _ = runPrivileged("pmset -a disablesleep 0")
    }

    @discardableResult
    func turnOn() -> Bool {
        guard !isOn else { return true }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-dimsu"]
        do {
            try process.run()
        } catch {
            return false
        }
        caffeinateProcess = process

        guard runPrivileged("pmset -a disablesleep 1") else {
            process.terminate()
            caffeinateProcess = nil
            return false
        }

        isOn = true
        return true
    }

    @discardableResult
    func turnOff() -> Bool {
        guard isOn else { return true }

        // If the admin prompt is cancelled/fails, leave everything exactly as it
        // was (caffeinate still running, isOn still true) instead of reporting
        // "off" while disablesleep is actually still 1 on the system. State only
        // ever changes when it's confirmed to match reality.
        guard runPrivileged("pmset -a disablesleep 0") else {
            return false
        }

        caffeinateProcess?.terminate()
        caffeinateProcess = nil
        isOn = false
        return true
    }

    // MARK: - Shell helpers

    private func currentDisableSleepValue() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]

        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("disablesleep") {
                return trimmed.split(separator: " ").last.map(String.init)
            }
        }
        return nil
    }

    /// Runs a command with `do shell script ... with administrator privileges`,
    /// which shows macOS's standard one-time GUI admin prompt.
    private func runPrivileged(_ command: String) -> Bool {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        do {
            try process.run()
        } catch {
            return false
        }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
