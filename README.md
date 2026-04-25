# QuickOpen

Switch Dock apps instantly with **Right ⌘ + Number**.

Press Right Command and a number key (1–9) to activate the corresponding app in your Dock. `0` activates the 10th app.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/runzhen/quickopen/main/install.sh | bash
```

This downloads the latest release, extracts `QuickOpen.app`, and moves it to `/Applications`.

## Permissions

On first launch, macOS will prompt for **Accessibility** permission. Grant it in:

**System Settings → Privacy & Security → Accessibility**

QuickOpen needs this to monitor keyboard shortcuts and read the Dock layout.

## Usage

| Shortcut | Action |
|----------|--------|
| Right ⌘ + 1 | Activate 1st Dock app |
| Right ⌘ + 2 | Activate 2nd Dock app |
| ... | ... |
| Right ⌘ + 9 | Activate 9th Dock app |
| Right ⌘ + 0 | Activate 10th Dock app |

A `⌘` icon appears in the menu bar. Use it to check permissions or quit.

Left Command + Number is **not** intercepted — only Right Command.

## Build from Source

Requires macOS 13+ and Swift 5.9+.

```bash
swift build -c release
./scripts/build-app.sh
open build/QuickOpen.app
```

## Uninstall

```bash
rm -rf /Applications/QuickOpen.app
```

## License

MIT
