import CoreGraphics
import Foundation

class KeyboardMonitor {
    static var shared: KeyboardMonitor?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onTrigger: (Int) -> Void

    // Track Right Command state via device-specific flag
    private static var rightCmdDown = false

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
            if keycode == 54 { // Right Command keycode
                // NX_DEVICERCMDKEYMASK = 0x10 in the device-dependent flag bits
                let flags = event.flags
                rightCmdDown = flags.contains(.maskCommand) && (flags.rawValue & 0x10) != 0
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown && rightCmdDown {
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
}
