import AppKit
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var keyboardMonitor: KeyboardMonitor?
    private var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        startMonitoringIfTrusted()
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.title = "⌘"
            button.toolTip = "qopen — Right ⌘ + Number to switch Dock apps"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Check Permissions…", action: #selector(requestPermission), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: - Permissions

    private func startMonitoringIfTrusted() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            startMonitoring()
        } else {
            NSLog("qopen: Accessibility permission not granted. Waiting…")
            pollForPermission()
        }
    }

    /// Poll every 2 s until the user grants Accessibility permission.
    private func pollForPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            if AXIsProcessTrusted() {
                self.startMonitoring()
            } else {
                self.pollForPermission()
            }
        }
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        guard keyboardMonitor == nil else { return }
        keyboardMonitor = KeyboardMonitor { index in
            DockManager.activateDockApp(at: index)
        }
        if keyboardMonitor!.start() {
            NSLog("qopen: Monitoring started — Right ⌘ + number to switch Dock apps")
        } else {
            NSLog("qopen: Failed to create event tap. Check Input Monitoring / Accessibility permissions.")
        }
    }

    // MARK: - Actions

    @objc private func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options), keyboardMonitor == nil {
            startMonitoring()
        }
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
    }

    @objc private func terminate() {
        keyboardMonitor?.stop()
        NSApp.terminate(nil)
    }
}
