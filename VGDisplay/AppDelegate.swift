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

import Foundation
import Cocoa

// Move Resolution and predefResolutions to Resolutions.swift

class AppDelegate: NSObject, NSApplicationDelegate {

    struct SavedDisplay: Codable {
        let width: Int32
        let height: Int32
        let ppi: Int32
        let hiDPI: Bool
        let name: String
        let serialNum: Int32
        let productID: Int32
        let vendorID: Int32
        let number: Int
    }

    let savedDisplaysKey = "SavedVirtualDisplays"

// Use Resolution and predefResolutions from Resolutions.swift
// ...existing code...

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

        // Restore saved virtual displays
        restoreVirtualDisplays()
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

                    // Save this display
                    saveVirtualDisplay(SavedDisplay(
                        width: resolution.width,
                        height: resolution.height,
                        ppi: resolution.ppi,
                        hiDPI: resolution.hiDPI,
                        name: name,
                        serialNum: Int32(serialNum),
                        productID: Int32(productID),
                        vendorID: Int32(vendorID),
                        number: virtualDisplayCounter
                    ))

                    virtualDisplayCounter += 1
                }
            }
        }
    }

    @objc func deleteDisplay(_ sender: AnyObject?) {
        if let menuItem = sender as? NSMenuItem {
            virtualDisplays[menuItem.tag] = nil
            menuItem.menu?.removeItem(menuItem)

            // Remove from saved displays
            removeSavedVirtualDisplay(number: menuItem.tag)

            if deleteMenu.numberOfItems == 0 {
                deleteSubmenu.isHidden = true
            }
            virtualDisplayCounter -= 1
        }
    }

    // MARK: - Persistence

    func saveVirtualDisplay(_ display: SavedDisplay) {
        var saved = loadSavedVirtualDisplays()
        saved.append(display)
        saveAllVirtualDisplays(saved)
    }

    func removeSavedVirtualDisplay(number: Int) {
        var saved = loadSavedVirtualDisplays()
        saved.removeAll { $0.number == number }
        saveAllVirtualDisplays(saved)
    }

    func saveAllVirtualDisplays(_ displays: [SavedDisplay]) {
        if let data = try? JSONEncoder().encode(displays) {
            UserDefaults.standard.set(data, forKey: savedDisplaysKey)
        }
    }

    func loadSavedVirtualDisplays() -> [SavedDisplay] {
        if let data = UserDefaults.standard.data(forKey: savedDisplaysKey),
           let displays = try? JSONDecoder().decode([SavedDisplay].self, from: data) {
            return displays
        }
        return []
    }

    func restoreVirtualDisplays() {
        let saved = loadSavedVirtualDisplays()
        for display in saved {
            if let created = createVirtualDisplay(display.width, display.height, display.ppi, display.hiDPI, display.name, display.serialNum, display.productID, display.vendorID) {
                virtualDisplays[display.number] = VirtualDisplay(number: display.number, display: created)
                let menuItem = NSMenuItem(title: "\(display.name) (\(display.width)×\(display.height))", action: #selector(deleteDisplay(_:)), keyEquivalent: "")
                menuItem.tag = display.number
                deleteMenu.addItem(menuItem)
                deleteSubmenu.isHidden = false
                if display.number >= virtualDisplayCounter {
                    virtualDisplayCounter = display.number + 1
                }
            }
        }
    }
}
