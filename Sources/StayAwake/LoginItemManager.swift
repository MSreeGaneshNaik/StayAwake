import ServiceManagement

/// Wraps SMAppService login-item registration for the "Launch at Login" menu toggle.
enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration only works from a properly bundled, launch-services-registered
            // .app (see README packaging step) — silently no-op otherwise.
        }
    }
}
