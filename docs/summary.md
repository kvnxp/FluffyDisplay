# FluffyDisplay - Project Summary

## What is FluffyDisplay?

A macOS menu-bar application that creates **virtual displays** on your Mac, allowing another Mac to use it as an external monitor via **Screen Sharing** over the local network (Bonjour/mDNS).

---

## Two Apps in One Repository

| App | Purpose | Key Feature |
|-----|---------|-------------|
| **FluffyDisplay** | Networked virtual displays | Bonjour discovery, peer-to-peer Screen Sharing, **persistent displays (UserDefaults)** |
| **VGDisplay** | Standalone virtual displays | Persistent displays across reboots (UserDefaults) |

---

## Core Technologies

| Layer | Technology |
|-------|------------|
| **Virtual Display** | Private CoreGraphics APIs (`CGVirtualDisplay*`) |
| **Bridge** | Objective-C (`VirtualDisplay.m`) → Swift |
| **Networking** | `NetService` / `NetServiceBrowser` (Bonjour/mDNS) |
| **Service Type** | `_fi-iki-tml-flfd._tcp` |
| **Data Exchange** | DNS-SD TXT Records |
| **Remote Access** | `vnc://` URLs → macOS Screen Sharing |
| **Persistence (VGDisplay)** | `UserDefaults` + `Codable` (JSON) |
| **Persistence (FluffyDisplay)** | `UserDefaults` + `Codable` (JSON) |
| **UI** | AppKit (NSStatusItem, NSMenu) |

---

## Key Files

| File | Lines | Role |
|------|-------|------|
| `FluffyDisplay/AppDelegate.swift` | 426 | Main app logic, menu bar, Bonjour, virtual display management |
| `VGDisplay/AppDelegate.swift` | 225 | Standalone app with persistence |
| `FluffyDisplay/VirtualDisplay.m` | 61 | CGVirtualDisplay bridge (fixed IDs) |
| `VGDisplay/VirtualDisplay.m` | 61 | CGVirtualDisplay bridge (unique IDs) |
| `VGDisplay/Resolutions.swift` | ~50 | Shared display resolution definitions |
| `include/CGVirtualDisplay*.h` | ~200 | Private CG API headers |

---

## How It Works (FluffyDisplay)

```
┌─────────────┐     Bonjour      ┌─────────────┐
│  Main Mac   │  ◄─────────────► │  Peer Mac   │
│ (FluffyDisp)│  discovers       │ (FluffyDisp)│
└──────┬──────┘                  └──────┬──────┘
       │                                │
       │ 1. Create virtual display      │
       │ 2. Advertise via TXT record    │
       │                                │ 3. See peer's displays in menu
       │                                │ 4. Select → creates local virtual display
       │                                │ 5. Sends "request" TXT record
       │ 6. Receives request            │
       │ 7. Opens vnc:// URL            │
       ▼                                ▼
┌────────────────────────────────────────────────┐
│         Screen Sharing (macOS built-in)        │
│  Peer connects to Main Mac's virtual display   │
└────────────────────────────────────────────────┘
```

---

## Predefined Resolutions (27)

From Apple displays + Wikipedia standards:
- 6K: 6016×3384 (Pro Display XDR)
- 5K: 5120×2880 (Studio Display, 27" iMac 5K)
- 4.5K: 4480×2520 (24" iMac)
- 4K/UHD: 3840×2160, 4096×2304
- Ultrawide: 5120×2160 (21:9), 5120×1440 (32:9), 3840×1600, 3440×1440
- MacBook Pro: 3456×2234 (16"), 3024×1964 (14"), 3072×1920 (16" old)
- MacBook Air: 2880×1864 (15"), 2560×1664 (13")
- Legacy: 2560×1440, 1920×1200, 1920×1080, 1680×1050, 1440×900, 1366×768, 1280×800

---

## Security & Distribution

| Aspect | Status |
|--------|--------|
| Sandboxed | ✅ Yes |
| Notarized | ✅ Yes |
| Signed | ✅ Yes |
| Mac App Store | ❌ No (uses private APIs) |
| Entitlement | `com.apple.security.temporary-exception.mach-lookup.global-name` |

---

## Known Issues

1. **Ghost cursor** - Cursor visible in Screen Sharing even when not on virtual display
2. **Manual steps required** - User must select display, enter observation mode, full-screen
3. **Video performance** - Not suitable for video playback
4. **Private API risk** - May break on macOS updates

---

## Future Ideas (from README)

- Apple native implementation (like Sidecar for iPad)
- Automated Screen Sharing configuration via URL parameters
- Better cursor handling
- WebRTC-based streaming alternative

---

## Build Requirements

- Xcode 15+
- macOS 13+ SDK
- Apple Developer account (for notarization)
- Entitlements file with Mach lookup exception

---

## License

Apache License 2.0 (see source file headers)

---

## Author

Tomi M. (fi.iki.tml)
- Open source, donations welcome (invoice or charity)
- Contact via GitHub for commercial inquiries