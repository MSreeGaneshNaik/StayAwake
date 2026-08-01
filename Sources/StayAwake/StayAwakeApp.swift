import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let controller = AwakeController()

    private var toggleItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // no Dock icon

        controller.resyncAfterCrashIfNeeded()

        let menu = NSMenu()

        toggleItem = NSMenuItem(title: "Stay Awake", action: #selector(toggleStayAwake), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
        updateUI()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.turnOff()
    }

    @objc private func toggleStayAwake() {
        if controller.isOn {
            controller.turnOff()
        } else {
            controller.turnOn()
        }
        updateUI()
    }

    @objc private func toggleLaunchAtLogin() {
        LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
        launchAtLoginItem.state = LoginItemManager.isEnabled ? .on : .off
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func updateUI() {
        let state: StatusIconState = controller.isOn ? .on : .off
        if let button = statusItem.button {
            button.image = state.icon
            button.toolTip = state.accessibilityDescription
        }
        toggleItem.state = controller.isOn ? .on : .off
    }
}

@main
struct StayAwakeMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
