// -*- Mode: Swift; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4; fill-column: 100 -*-

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Cocoa
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate {

    struct Resolution {
        let width, height, ppi: Int32
        let hiDPI: Bool
        let description: String
        init(_ width: Int32, _ height: Int32, _ ppi: Int32, _ hiDPI: Bool, _ description: String) {
            self.width = width
            self.height = height
            self.ppi = ppi
            self.hiDPI = hiDPI
            self.description = description
        }
        init(_ width: Int, _ height: Int, _ ppi: Int, _ hiDPI: Bool, _ description: String) {
            self.init(Int32(width), Int32(height), Int32(ppi), hiDPI, description)
        }
    }

    let predefResolutions: [Resolution] = [
      
      Resolution(6016, 3384, 218, true,  "Apple Pro Display XDR"),
      Resolution(5120, 2880, 218, true,  "UHD+, 27-inch Apple Studio Display, 27-inch iMac with Retina 5K display"),
      Resolution(4480, 2520, 218, true,  "24-inch iMac (23.5-inch)"),
      Resolution(5120, 2160, 200, true,  "21:9, 64∶27, 237:100 (27.8-inch)"),
      Resolution(4096, 2304, 219, true,  "21.5-inch iMac with Retina 4K display"),
      Resolution(3840, 2400, 200, true,  "WQUXGA"),
      Resolution(3840, 2160, 200, true,  "UHD"),
      Resolution(3456, 2234, 254, true,  "16.2-inch MacBook Pro"),
      Resolution(5120, 1440, 200, true,  "32:9, 356:100, DQHD (26.6-inch)"),
      Resolution(3840, 1600, 200, true,  "WQHD+, UW-QHD+, 21:9, 240:100 (20.8-inch)"),
      Resolution(3440, 1440, 200, true,  "21:9, 239:100 (18.6-inch)"),
      Resolution(3840, 1080, 200, true,  "DFHD"),
      Resolution(3024, 1964, 254, true,  "14.2-inch MacBook Pro"),
      Resolution(3072, 1920, 226, true,  "16-inch MacBook Pro with Retina display"),
      Resolution(2880, 1864, 224, true,  "15.3-inch MacBook Air"),
      Resolution(2880, 1800, 220, true,  "15.4-inch MacBook Pro with Retina display"),
      Resolution(2560, 1664, 224, true,  "13.6-inch MacBook Air"),
      Resolution(2560, 1600, 227, true,  "WQXGA, 13.3-inch MacBook Pro with Retina display"),
      Resolution(2560, 1440, 109, false, "27-inch Apple Thunderbolt display"),
      Resolution(2304, 1440, 226, true,  "12-inch MacBook with Retina display"),
      Resolution(2048, 1536, 150, false, "QXGA"),
      Resolution(2048, 1152, 150, false, "QWXGA"),
      Resolution(1920, 1200, 98,  false, "WUXGA, 23-inch Apple Cinema HD Display"),
      Resolution(1600, 1200, 125, false, "UXGA"),
      Resolution(1920, 1080, 102, false, "HD, 21.5-inch iMac"),
      Resolution(1680, 1050, 99,  false, "WSXGA+, Apple Cinema Display (20-inch), 20-inch iMac"),
      Resolution(1600, 1024, 86,  false, "WSXGA, Apple Cinema Display (22-inch)"),
      Resolution(1440, 900,  127, false, "WXGA+, 13.3-inch MacBook Air"),
      Resolution(1400, 1050, 125, false, "SXGA+"),
      Resolution(1366, 768,  135, false, "11.6-inch MacBook Air"),
      Resolution(1280, 1024, 100, false, "SXGA"),
      Resolution(1280, 800,  113, false, "13.3-inch MacBook Pro"),
    ]

    var activeDisplays = [Resolution]()

    // Represents one local virtual display
    struct VirtualDisplay {
        let number: Int
        let display: Any
    }

    var virtualDisplayCounter = 0
    var virtualDisplays = [Int: VirtualDisplay]()

    // Represents one (real) display on a peer running 
    struct PeerDisplay {
        let number: Int
        let peer: String
        let resolution: Resolution
    }
    var peerDisplayCounter = 0
    var peerDisplays = [Int: PeerDisplay]()

    var statusBarItem: NSStatusItem!

    let newSubmenu = NSMenuItem(title: "New", action: nil, keyEquivalent: "")

    let autoSubmenu = NSMenuItem(title: "New on peer", action: nil, keyEquivalent: "")
    let autoMenu = NSMenu()

    let deleteSubmenu = NSMenuItem(title: "Delete", action: nil, keyEquivalent: "")
    let deleteMenu = NSMenu()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 AppDelegate: applicationDidFinishLaunching called!")

        let maxDisplays: Int32 = 5
        var activeDisplayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var activeDisplayCount: UInt32 = 0

        if CGGetActiveDisplayList(UInt32(maxDisplays), &activeDisplayIDs, &activeDisplayCount) == .success {
            print("📺 Found \(activeDisplayCount) active displays")
            for i in (0...UInt32(activeDisplayCount)-1) {
                // Just use the current mode of the display
                if let mode = CGDisplayCopyDisplayMode(activeDisplayIDs[Int(i)]) {
                    let size = CGDisplayScreenSize(activeDisplayIDs[Int(i)])
                    activeDisplays.append(Resolution(Int32(mode.pixelWidth), Int32(mode.pixelHeight),
                                                     Int32(CGFloat(mode.pixelWidth) / size.width * 25.4),
                                                     mode.pixelWidth > mode.width,
                                                     CGDisplayIsBuiltin(activeDisplayIDs[Int(i)]) != 0 ? "Virtual Display" : "Display #\(i)"))
                }
            }
        }

        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = statusBarItem.button {
            if let icon = NSImage(named: "Icon") {
                button.image = icon
            } else {
                // Fallback to a system icon if custom icon is missing
                if #available(macOS 11.0, *) {
                    button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Display")
                } else {
                    // Use a generic template image for older macOS
                    let fallback = NSImage(named: NSImage.Name("NSApplicationIcon"))
                    fallback?.isTemplate = true
                    button.image = fallback
                }
            }
            print("📋 Menu bar item created")
        }

        let menu = NSMenu()
        let newMenu = NSMenu()

        var i = 0
        for size in predefResolutions {
            let item = NSMenuItem(title: "\(size.width)×\(size.height) (\(size.description)) \(size.hiDPI ? "HDPI":"SD")", action: #selector(newDisplay(_:)), keyEquivalent: "")
            item.tag = i
            newMenu.addItem(item)
            i += 1
        }

        newSubmenu.submenu = newMenu
        menu.addItem(newSubmenu)

        autoSubmenu.submenu = autoMenu
        menu.addItem(autoSubmenu)

        deleteSubmenu.submenu = deleteMenu
        menu.addItem(deleteSubmenu)

        // When we start we haven't found any other Macs and we don't have anythung to delete.
        autoSubmenu.isHidden = true
        deleteSubmenu.isHidden = true

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit VirtualDisplay", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusBarItem.menu = menu
    }

    @objc func newDisplay(_ sender: AnyObject?) {
        if let menuItem = sender as? NSMenuItem {
            if menuItem.tag >= 0 && menuItem.tag < predefResolutions.count {
                let resolution = predefResolutions[menuItem.tag]
                let name = "Virtual Display #\(virtualDisplayCounter)"
                // Generate unique vendorID, productID, serialNum for each display
                let vendorID: UInt32 = 0xF1F1 // Example static vendor ID
                let productID: UInt32 = 0xFD00 + UInt32(virtualDisplayCounter) // Example base product ID
                let serialNum: UInt32 = UInt32(virtualDisplayCounter + 1000) // Example offset for uniqueness
                
                if let display = createVirtualDisplay(resolution.width,
                                                      resolution.height,
                                                      resolution.ppi,
                                                      resolution.hiDPI,
                                                      name,
                                                      Int32(serialNum),
                                                      Int32(productID),
                                                      Int32(vendorID)) {
                    virtualDisplays[virtualDisplayCounter] = VirtualDisplay(number: virtualDisplayCounter, display: display)
                    let menuItem = NSMenuItem(title: "\(name) (\(resolution.width)×\(resolution.height))",
                                                    action: #selector(deleteDisplay(_:)),
                                                    keyEquivalent: "")
                    menuItem.tag = virtualDisplayCounter
                    deleteMenu.addItem(menuItem)
                    deleteSubmenu.isHidden = false

                    virtualDisplayCounter += 1
                }
            }
        }
    }

    @objc func deleteDisplay(_ sender: AnyObject?) {
        if let menuItem = sender as? NSMenuItem {
            virtualDisplays[menuItem.tag] = nil
            menuItem.menu?.removeItem(menuItem)
            
            if deleteMenu.numberOfItems == 0 {
                deleteSubmenu.isHidden = true
            }
            virtualDisplayCounter -= 1
        }
    }
}
