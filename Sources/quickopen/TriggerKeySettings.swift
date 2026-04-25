import Foundation
import CoreGraphics

/// Persists the user's chosen trigger key (keycode + display name) via UserDefaults.
struct TriggerKeySettings {
    private static let keycodeKey = "triggerKeycode"
    private static let nameKey = "triggerKeyName"
    private static let flagMaskKey = "triggerFlagMask"

    /// Default: Right Command (keycode 54, device flag 0x10 under maskCommand)
    static let defaultKeycode: Int64 = 54
    static let defaultName = "Right ⌘"
    static let defaultFlagMask: UInt64 = 0x10
    static let defaultParentFlag: UInt64 = CGEventFlags.maskCommand.rawValue

    static var keycode: Int64 {
        get {
            let v = UserDefaults.standard.integer(forKey: keycodeKey)
            return v == 0 ? defaultKeycode : Int64(v)
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: keycodeKey) }
    }

    static var keyName: String {
        get { UserDefaults.standard.string(forKey: nameKey) ?? defaultName }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    /// Device-dependent flag bit that must be set (e.g. 0x10 for Right Cmd).
    /// Set to 0 for non-modifier keys that use flagsChanged detection.
    static var flagMask: UInt64 {
        get {
            if UserDefaults.standard.object(forKey: flagMaskKey) == nil {
                return defaultFlagMask
            }
            return UInt64(UserDefaults.standard.integer(forKey: flagMaskKey))
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: flagMaskKey) }
    }

    /// Parent modifier flag category (e.g. maskCommand, maskShift, maskControl, maskAlternate).
    /// Stored so we know which top-level flag to check alongside the device mask.
    static var parentFlag: UInt64 {
        get {
            if UserDefaults.standard.object(forKey: "triggerParentFlag") == nil {
                return defaultParentFlag
            }
            return UInt64(UserDefaults.standard.integer(forKey: "triggerParentFlag"))
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: "triggerParentFlag") }
    }

    static func reset() {
        keycode = defaultKeycode
        keyName = defaultName
        flagMask = defaultFlagMask
        parentFlag = defaultParentFlag
    }
}
