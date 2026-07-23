# FluffyDisplay Architecture Documentation

## Overview

FluffyDisplay is a macOS application that creates **virtual displays** on a Mac, allowing it to act as a virtual monitor for another Mac via Screen Sharing. It enables using an older Mac as an external display for a newer main Mac.

**Primary Use Case**: Use an old iMac as an external display for a newer Mac via Screen Sharing over local network (Bonjour/mDNS).

**Key Feature**: Virtual displays persist across app restarts — created displays are automatically restored on launch.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FluffyDisplay (Main App)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌──────────────────┐    ┌────────────────────────┐ │
│  │   AppDelegate   │◄───│  VirtualDisplay  │◄───│  CGVirtualDisplay*     │ │
│  │  (Swift/Obj-C)  │    │  (Obj-C Bridge)  │    │  (Private CG API)      │ │
│  └────────┬────────┘    └────────┬─────────┘    └──────────┬─────────────┘ │
│           │                      │                         │              │
│           ▼                      ▼                         ▼              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Network Layer (Bonjour/mDNS)                   │   │
│  │  ┌──────────────┐  ┌─────────────────┐  ┌────────────────────────┐ │   │
│  │  │ NetService   │  │ NetServiceBrowser│  │   TXT Records (DNS-SD)  │ │   │
│  │  │ (Publisher)  │  │ (Discoverer)     │  │   • Display configs    │ │   │
│  │  │              │  │                 │  │   • Peer discovery     │ │   │
│  │  │  _fi-iki-    │  │  _fi-iki-       │  │   • Connection requests│ │   │
│  │  │  tml-flfd    │  │  tml-flfd       │  │                        │ │   │
│  │  └──────────────┘  └─────────────────┘  └────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
           ┌──────────────────┐            ┌──────────────────┐
           │  Main Mac        │            │  Peer Mac        │
           │  (Display Source)│            │  (FluffyDisplay) │
           │                  │            │                  │
           │  Virtual Display │◄──Screen   │  Screen Sharing  │
           │  (CGVirtualDisplay)  Sharing  │  (Observer Mode) │
           └──────────────────┘            └──────────────────┘
```

---

## Core Components

### 1. **FluffyDisplay/AppDelegate.swift** (Main App - 426 lines)
**Primary entry point** - Menu bar app that creates virtual displays and advertises them via Bonjour.

**Key Responsibilities:**
- Menu bar integration with NSStatusItem
- Virtual display creation/deletion via menu
- Bonjour service publishing (`_fi-iki-tml-flfd._tcp`)
- Peer discovery via NetServiceBrowser
- TXT record management for display advertisement
- Screen Sharing URL launching for peer connections

**Key Data Structures:**
```swift
struct Resolution {
    let width, height, ppi: Int32
    let hiDPI: Bool
    let description: String
}

struct VirtualDisplay {
    let number: Int
    let display: Any  // CGVirtualDisplay reference
}

struct PeerDisplay {
    let number: Int
    let peer: String
    let resolution: Resolution
}
```

**Menu Structure:**
- **New** → Predefined resolutions (27 options from Wikipedia/Apple specs)
- **New on peer** → Discovered peer displays
- **Delete** → Remove created virtual displays

**Network Protocol (TXT Records):**
- Type `"displays"`: Advertise local physical displays
- Type `"request"`: Request peer to connect via Screen Sharing

---

### 2. **VGDisplay/AppDelegate.swift** (Alternative App - 225 lines)
**Second app variant** - Persists virtual displays across restarts using UserDefaults.

**Key Differences from FluffyDisplay:**
- **Persistence**: Saves/restores virtual displays via `SavedDisplay` (Codable)
- **No Bonjour networking**: Standalone virtual display manager
- **Unique identifiers**: Each display gets unique vendorID, productID, serialNum
- **Resolution definitions**: Moved to separate `Resolutions.swift`

**Persistence Model:**
```swift
struct SavedDisplay: Codable {
    let width, height, ppi: Int32
    let hiDPI: Bool
    let name: String
    let serialNum, productID, vendorID: Int32
    let number: Int
}
```

---

### 3. **VirtualDisplay.m / .h** (Objective-C Bridge - 61 lines)
**Bridge layer** between Swift AppDelegate and private CoreGraphics APIs.

**FluffyDisplay Version** (fixed identifiers):
```objc
id createVirtualDisplay(int width, int height, int ppi, BOOL hiDPI, NSString *name)
```

**VGDisplay Version** (unique identifiers):
```objc
id createVirtualDisplay(int width, int height, int ppi, BOOL hiDPI, 
                        NSString *name, int serialNum, int productId, int vendorId)
```

**Implementation Flow:**
1. Create `CGVirtualDisplaySettings` with HiDPI flag
2. Create `CGVirtualDisplayDescriptor` with display properties
3. Set color primaries (Apple display standard values)
4. Calculate physical size from PPI
5. Create `CGVirtualDisplay` instance
6. Configure display mode (60Hz refresh)
7. Apply settings

---

### 4. **Private CoreGraphics Framework** (include/*.h)
**Reverse-engineered headers** for undocumented CGVirtualDisplay APIs:
- `CGVirtualDisplay.h` - Main display class
- `CGVirtualDisplayDescriptor.h` - Display configuration
- `CGVirtualDisplayMode.h` - Display modes (resolution, refresh rate)
- `CGVirtualDisplaySettings.h` - Settings container
- `original-dump/` - Original class-dump output

**Key Classes:**
```objc
@interface CGVirtualDisplay : NSObject
- (id)initWithDescriptor:(id)descriptor;
- (BOOL)applySettings:(id)settings;
@end

@interface CGVirtualDisplayDescriptor : NSObject
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) CGPoint whitePoint, redPrimary, greenPrimary, bluePrimary;
@property (nonatomic) NSUInteger maxPixelsWide, maxPixelsHigh;
@property (nonatomic) CGSize sizeInMillimeters;
@property (nonatomic) unsigned int serialNum, productID, vendorID;
@end

@interface CGVirtualDisplayMode : NSObject
- (id)initWithWidth:(NSUInteger)width height:(NSUInteger)height refreshRate:(double)rate;
@end
```

---

### 5. **Bridging Headers**
- `FluffyDisplay-Bridging-Header.h` - Imports CGVirtualDisplay headers for FluffyDisplay
- `VGDisplay-Bridging-Header.h` - Imports for VGDisplay

---

## Data Flow

### Virtual Display Creation (FluffyDisplay)
```
User clicks "New" → AppDelegate.newDisplay()
    → createVirtualDisplay(width, height, ppi, hiDPI, name) [VirtualDisplay.m]
        → CGVirtualDisplaySettings + CGVirtualDisplayDescriptor
        → CGVirtualDisplay.initWithDescriptor()
        → applySettings() with CGVirtualDisplayMode
    → Add to virtualDisplays dictionary
    → Add menu item to "Delete" submenu
    → Clear TXT record (becomes "main" Mac)
```

### Peer Discovery & Connection
```
NetServiceBrowser finds peer
    → startMonitoring() on peer service
    → netService:didUpdateTXTRecord:data:
        → Parse TXT record type "displays"
        → Build "New on peer" menu with peer's displays
        
User selects peer display
    → newAutoDisplay()
    → createVirtualDisplay() locally
    → advertiseRequestToConnect() via TXT record type "request"
    
Peer receives "request" TXT record
    → Opens vnc:// URL via NSWorkspace
    → Screen Sharing connects to virtual display
```

### Persistence (VGDisplay Only)
```
App launch → restoreVirtualDisplays()
    → loadSavedVirtualDisplays() from UserDefaults
    → For each saved: createVirtualDisplay() with saved IDs
    → Rebuild delete menu
    
Create display → saveVirtualDisplay() → JSON encode → UserDefaults
Delete display → removeSavedVirtualDisplay() → JSON encode → UserDefaults
```

---

## Network Architecture

### Bonjour Service Type
```
Service Type: _fi-iki-tml-flfd._tcp
Domain: local.
```

### TXT Record Format

**Type: "displays" (Advertise physical displays)**
```
--type=displays
ndisplays=N
width0=WIDTH height0=HEIGHT ppi0=PPI hidpi0=0/1 name0=NAME
width1=... ...
```

**Type: "request" (Request Screen Sharing connection)**
```
--type=request
source=PEER_NAME
```

---

## Security Model

- **Sandboxed** macOS app (App Store compatible except for private API usage)
- **Entitlement Required**: `com.apple.security.temporary-exception.mach-lookup.global-name`
- Uses **undocumented CoreGraphics APIs** → Not Mac App Store eligible
- **Notarized & signed** for distribution outside App Store
- Screen Sharing connection initiated by user action (not automated)

---

## Project Structure

```
FluffyDisplay-main/
├── FluffyDisplay/                 # Main app (menu bar + Bonjour)
│   ├── AppDelegate.swift           # 426 lines - Main logic
│   ├── VirtualDisplay.m/.h         # CG bridge (fixed IDs)
│   ├── FluffyDisplay-Bridging-Header.h
│   └── Assets.xcassets
│
├── VGDisplay/                      # Alternative app (persistent displays)
│   ├── AppDelegate.swift           # 225 lines - Persistence
│   ├── VirtualDisplay.m/.h         # CG bridge (unique IDs)
│   ├── Resolutions.swift           # Shared resolution definitions
│   ├── VGDisplay-Bridging-Header.h
│   └── main.swift                  # Entry point
│
├── include/                        # Private CG headers
│   ├── CGVirtualDisplay*.h         # 4 main headers
│   └── original-dump/              # Original class-dump output
│
├── README.md                       # User documentation
└── docs/                           # This documentation
    ├── architecture.md
    └── summary.md
```

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Two separate apps | Different use cases: networked vs. standalone |
| Private CG APIs | Only way to create virtual displays on macOS |
| Bonjour for discovery | Zero-config local network discovery |
| TXT records for metadata | Lightweight, fits in mDNS packets |
| Screen Sharing (VNC) | Native macOS, no extra software needed |
| Sandbox + notarization | Security best practice for distribution |
| Objective-C bridge | Swift can't directly call private Obj-C APIs |
| Fixed vs unique IDs | FluffyDisplay: simpler, VGDisplay: persistence needs uniqueness |

---

## Extension Points

1. **Add resolutions** → Modify `predefResolutions` in `Resolutions.swift` or `AppDelegate.swift`
2. **Custom display properties** → Extend `CGVirtualDisplayDescriptor` properties
3. **Alternative transport** → Replace Bonjour with WebRTC, etc.
4. **Persistence backend** → Swap UserDefaults for Core Data, CloudKit, etc.
5. **Menu bar UI** → Rewrite in SwiftUI (currently AppKit)

---

## Dependencies

- **System Frameworks**: Foundation, AppKit, CoreGraphics, Network
- **Private Framework**: CoreGraphics (CGVirtualDisplay* - undocumented)
- **Language**: Swift 5+, Objective-C (for CG bridge)
- **Minimum macOS**: 10.15+ (Catalyst compatible)
- **Build**: Xcode project (not included in repo)

---

## Persistence (New in FluffyDisplay)

FluffyDisplay now persists virtual displays across app restarts using `UserDefaults` with `Codable` (JSON encoding).

### Data Model (`SavedDisplay`)

```swift
struct SavedDisplay: Codable {
    let width: Int32
    let height: Int32
    let ppi: Int32
    let hiDPI: Bool
    let name: String
    let number: Int
}
```

### Lifecycle

1. **On Display Creation** (`newDisplay`): 
   - Creates virtual display via `CGVirtualDisplay`
   - Saves `SavedDisplay` to UserDefaults (key: `SavedVirtualDisplays`)

2. **On App Launch** (`applicationDidFinishLaunching`):
   - Calls `restoreVirtualDisplays()`
   - Loads saved displays from UserDefaults
   - Recreates each via `createVirtualDisplay`
   - Rebuilds delete menu items
   - Updates `virtualDisplayCounter` to avoid conflicts

3. **On Display Deletion** (`deleteDisplay`):
   - Removes from in-memory `virtualDisplays` dictionary
   - Removes menu item
   - Removes from UserDefaults via `removeSavedVirtualDisplay(number:)`

### Storage Format

JSON array in `UserDefaults.standard` under key `"SavedVirtualDisplays"`:

```json
[
  {
    "width": 3840,
    "height": 2160,
    "ppi": 200,
    "hiDPI": true,
    "name": "FluffyDisplay Virtual Display #0",
    "number": 0
  }
]
```

---

## Known Limitations

1. **Ghost cursor** - Cursor visible in Screen Sharing even when not on virtual display
2. **No video optimization** - Not suitable for video playback
3. **Manual Screen Sharing steps** - User must select display, enter observation mode, full-screen
4. **Private API risk** - May break on macOS updates
5. **Sandbox restrictions** - Limits automation capabilities