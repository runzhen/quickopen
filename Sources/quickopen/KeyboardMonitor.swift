import CoreGraphics
import Foundation

class KeyboardMonitor {
    static var shared: KeyboardMonitor?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onTrigger: (Int) -> Void

    // Configurable trigger key
    private static var triggerKeycode: Int64 = TriggerKeySettings.keycode
    private static var triggerFlagMask: UInt64 = TriggerKeySettings.flagMask
    private static var triggerParentFlag: UInt64 = TriggerKeySettings.parentFlag
    private static var triggerDown = false

    init(onTrigger: @escaping (Int) -> Void) {
        self.onTrigger = onTrigger
        KeyboardMonitor.shared = self
    }

    func start() -> Bool {
        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: KeyboardMonitor.callback,
            userInfo: nil
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    // CGEventTapCallBack — must be a static/global C-compatible function
    private static let callback: CGEventTapCallBack = { _, type, event, _ in
        // Re-enable tap if the system disabled it
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = shared?.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if keycode == triggerKeycode {
                let flags = event.flags
                if triggerFlagMask != 0 {
                    triggerDown = (flags.rawValue & triggerParentFlag) != 0 && (flags.rawValue & triggerFlagMask) != 0
                } else {
                    triggerDown = (flags.rawValue & triggerParentFlag) != 0
                }
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown && triggerDown {
            // Ignore auto-repeat (key held down)
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
                return nil // consume repeated events silently
            }
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if let index = numberFromKeycode(keycode) {
                DispatchQueue.main.async {
                    shared?.onTrigger(index)
                }
                return nil // consume the event
            }
        }

        return Unmanaged.passUnretained(event)
    }

    /// Map number-row virtual keycodes to Dock indices 1–10 (0 key → 10).
    private static func numberFromKeycode(_ code: Int64) -> Int? {
        switch code {
        case 18: return 1   // 1
        case 19: return 2   // 2
        case 20: return 3   // 3
        case 21: return 4   // 4
        case 23: return 5   // 5
        case 22: return 6   // 6
        case 26: return 7   // 7
        case 28: return 8   // 8
        case 25: return 9   // 9
        case 29: return 10  // 0 → index 10
        default: return nil
        }
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    /// Reload trigger key settings (called when user changes preferences).
    func reloadTriggerKey() {
        KeyboardMonitor.triggerKeycode = TriggerKeySettings.keycode
        KeyboardMonitor.triggerFlagMask = TriggerKeySettings.flagMask
        KeyboardMonitor.triggerParentFlag = TriggerKeySettings.parentFlag
        KeyboardMonitor.triggerDown = false
    }
}
