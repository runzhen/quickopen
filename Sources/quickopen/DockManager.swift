import AppKit
import ApplicationServices

/// Reads the Dock's app items via the Accessibility API and activates them.
enum DockManager {

    static func activateDockApp(at index: Int) {
        let items = getDockAppItems()
        guard index >= 1, index <= items.count else {
            NSLog("quickopen: Index %d out of range (Dock has %d apps).", index, items.count)
            return
        }
        let item = items[index - 1]
        let name = axTitle(of: item) ?? "?"
        let err = AXUIElementPerformAction(item, kAXPressAction as CFString)
        if err == .success {
            NSLog("quickopen: Activated #%d — %@", index, name)
        } else {
            NSLog("quickopen: Failed to activate #%d (%@), AXError %d", index, name, err.rawValue)
        }
    }

    // MARK: - Private

    /// Returns the application dock items (left section of the Dock, before the first separator).
    private static func getDockAppItems() -> [AXUIElement] {
        guard let dockPID = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == "com.apple.dock" })?
            .processIdentifier else {
            NSLog("quickopen: Dock process not found.")
            return []
        }

        let dockApp = AXUIElementCreateApplication(dockPID)

        guard let children = axValue(dockApp, kAXChildrenAttribute) as? [AXUIElement] else {
            return []
        }

        // The Dock exposes one or more AXList children.
        // The first AXList contains the app section.
        for child in children {
            guard let role = axValue(child, kAXRoleAttribute) as? String,
                  role == "AXList" else { continue }

            guard let items = axValue(child, kAXChildrenAttribute) as? [AXUIElement] else {
                continue
            }

            var appItems: [AXUIElement] = []
            for item in items {
                let subrole = axValue(item, kAXSubroleAttribute) as? String
                if subrole == "AXSeparatorDockItem" {
                    break // stop at the first separator (end of apps section)
                }
                if subrole == "AXApplicationDockItem" {
                    appItems.append(item)
                }
            }
            if !appItems.isEmpty {
                return appItems
            }
        }

        return []
    }

    private static func axValue(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success else {
            return nil
        }
        return ref
    }

    private static func axTitle(of element: AXUIElement) -> String? {
        axValue(element, kAXTitleAttribute) as? String
    }
}
