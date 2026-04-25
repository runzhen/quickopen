import AppKit
import Carbon.HIToolbox

/// A small preferences window that lets the user press any key to set it as the trigger modifier.
class PreferencesWindowController: NSWindowController {

    private let instructionLabel = NSTextField(labelWithString: "")
    private let currentKeyLabel = NSTextField(labelWithString: "")
    private let resetButton = NSButton(title: "Reset to Default (Right ⌘)", target: nil, action: nil)
    private var keyMonitor: Any?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "QOpen Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        instructionLabel.stringValue = "Press any modifier key to set as trigger:"
        instructionLabel.font = .systemFont(ofSize: 13)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        currentKeyLabel.font = .boldSystemFont(ofSize: 18)
        currentKeyLabel.alignment = .center
        currentKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        updateCurrentKeyLabel()

        resetButton.target = self
        resetButton.action = #selector(resetToDefault)
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(instructionLabel)
        contentView.addSubview(currentKeyLabel)
        contentView.addSubview(resetButton)

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            instructionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            currentKeyLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            currentKeyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            currentKeyLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40),

            resetButton.topAnchor.constraint(equalTo: currentKeyLabel.bottomAnchor, constant: 20),
            resetButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }

    private func updateCurrentKeyLabel() {
        currentKeyLabel.stringValue = "Current: \(TriggerKeySettings.keyName)"
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startListening()
    }

    func windowWillClose(_ notification: Notification) {
        stopListening()
    }

    // MARK: - Key capture

    private func startListening() {
        stopListening()
        // Use flagsChanged monitor to capture modifier key presses
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }

    private func stopListening() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let keycode = event.keyCode

        // Only act on key-down (flag appeared), not key-up
        guard event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue != 0 else {
            return
        }

        guard let (name, flagMask, parentFlag) = identifyModifierKey(keycode: keycode) else {
            return
        }

        TriggerKeySettings.keycode = Int64(keycode)
        TriggerKeySettings.keyName = name
        TriggerKeySettings.flagMask = flagMask
        TriggerKeySettings.parentFlag = parentFlag

        updateCurrentKeyLabel()
        KeyboardMonitor.shared?.reloadTriggerKey()
        NSLog("qopen: Trigger key changed to %@ (keycode %d)", name, keycode)
    }

    /// Map known modifier keycodes to a human-readable name, device flag mask, and parent flag.
    private func identifyModifierKey(keycode: UInt16) -> (String, UInt64, UInt64)? {
        switch keycode {
        // Command keys
        case 54: return ("Right ⌘", 0x10, CGEventFlags.maskCommand.rawValue)
        case 55: return ("Left ⌘", 0x08, CGEventFlags.maskCommand.rawValue)
        // Shift keys
        case 56: return ("Left ⇧", 0x02, CGEventFlags.maskShift.rawValue)
        case 60: return ("Right ⇧", 0x04, CGEventFlags.maskShift.rawValue)
        // Option keys
        case 58: return ("Left ⌥", 0x20, CGEventFlags.maskAlternate.rawValue)
        case 61: return ("Right ⌥", 0x40, CGEventFlags.maskAlternate.rawValue)
        // Control keys
        case 59: return ("Left ⌃", 0x01, CGEventFlags.maskControl.rawValue)
        case 62: return ("Right ⌃", 0x2000, CGEventFlags.maskControl.rawValue)
        // Fn / Globe key
        case 63: return ("Fn/🌐", 0x00, CGEventFlags.maskSecondaryFn.rawValue)
        // Caps Lock
        case 57: return ("⇪ Caps Lock", 0x00, CGEventFlags.maskAlphaShift.rawValue)
        default: return nil
        }
    }

    @objc private func resetToDefault() {
        TriggerKeySettings.reset()
        updateCurrentKeyLabel()
        KeyboardMonitor.shared?.reloadTriggerKey()
        NSLog("qopen: Trigger key reset to Right ⌘")
    }

    deinit {
        stopListening()
    }
}
