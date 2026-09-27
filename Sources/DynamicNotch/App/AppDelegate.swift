import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let stateManager = NotchStateManager.shared
    private let nowPlayingManager = NowPlayingManager.shared
    private let dropShelfManager = DropShelfManager.shared
    private let audioMonitor = AudioMonitor.shared
    private let brightnessMonitor = BrightnessMonitor.shared
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as menu bar accessory / background app
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Setup Overlay Window
        NotchWindowController.shared.setupWindow(with: stateManager)
        
        // Setup Menu Bar Status Item
        setupStatusItem()
        
        // Start Media Key Tap
        MediaKeyTapManager.shared.start()
        
        print("[DynamicNotch] Initialized successfully with Drop Shelf.")
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "waveform.circle.fill",
                accessibilityDescription: "Dynamic Notch"
            )
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "Dynamic Notch v1.1", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // Drop Shelf Submenu
        let shelfMenu = NSMenu()
        let openShelfItem = NSMenuItem(title: "Open Shelf Drawer", action: #selector(openShelf), keyEquivalent: "s")
        openShelfItem.target = self
        shelfMenu.addItem(openShelfItem)
        
        let addDemoFileItem = NSMenuItem(title: "Add Sample File to Shelf", action: #selector(addDemoFile), keyEquivalent: "")
        addDemoFileItem.target = self
        shelfMenu.addItem(addDemoFileItem)
        
        let clearShelfItem = NSMenuItem(title: "Clear Shelf Items", action: #selector(clearShelf), keyEquivalent: "")
        clearShelfItem.target = self
        shelfMenu.addItem(clearShelfItem)
        
        let shelfSubItem = NSMenuItem(title: "Notch Shelf (Dosya Rafı)", action: nil, keyEquivalent: "")
        shelfSubItem.submenu = shelfMenu
        menu.addItem(shelfSubItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Demo Player Toggle
        let demoItem = NSMenuItem(
            title: "Simulate Playing Music",
            action: #selector(toggleDemoPlayer),
            keyEquivalent: "d"
        )
        demoItem.target = self
        menu.addItem(demoItem)
        
        // Next Demo Track
        let nextDemoItem = NSMenuItem(
            title: "Next Demo Track",
            action: #selector(nextDemoTrack),
            keyEquivalent: "n"
        )
        nextDemoItem.target = self
        menu.addItem(nextDemoItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Volume Simulation Submenu
        let volMenu = NSMenu()
        let volUpItem = NSMenuItem(title: "Volume Up (+10%)", action: #selector(simulateVolUp), keyEquivalent: "")
        volUpItem.target = self
        volMenu.addItem(volUpItem)
        
        let volDownItem = NSMenuItem(title: "Volume Down (-10%)", action: #selector(simulateVolDown), keyEquivalent: "")
        volDownItem.target = self
        volMenu.addItem(volDownItem)
        
        let volMuteItem = NSMenuItem(title: "Toggle Mute", action: #selector(simulateMuteToggle), keyEquivalent: "")
        volMuteItem.target = self
        volMenu.addItem(volMuteItem)
        
        let volSubItem = NSMenuItem(title: "Test Volume HUD (Çentik Altı)", action: nil, keyEquivalent: "")
        volSubItem.submenu = volMenu
        menu.addItem(volSubItem)
        
        // Brightness Simulation Submenu
        let brightMenu = NSMenu()
        let brUpItem = NSMenuItem(title: "Brightness Up (+10%)", action: #selector(simulateBrightUp), keyEquivalent: "")
        brUpItem.target = self
        brightMenu.addItem(brUpItem)
        
        let brDownItem = NSMenuItem(title: "Brightness Down (-10%)", action: #selector(simulateBrightDown), keyEquivalent: "")
        brDownItem.target = self
        brightMenu.addItem(brDownItem)
        
        let brightSubItem = NSMenuItem(title: "Test Brightness HUD", action: nil, keyEquivalent: "")
        brightSubItem.submenu = brightMenu
        menu.addItem(brightSubItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Expand/Collapse Toggle
        let expandItem = NSMenuItem(
            title: "Toggle Expanded View",
            action: #selector(toggleExpanded),
            keyEquivalent: "e"
        )
        expandItem.target = self
        menu.addItem(expandItem)
        
        // Reposition Notch
        let repositionItem = NSMenuItem(
            title: "Recalculate Notch Position",
            action: #selector(repositionNotch),
            keyEquivalent: "r"
        )
        repositionItem.target = self
        menu.addItem(repositionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Dynamic Notch",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    // MARK: - Shelf Actions
    
    @objc private func openShelf() {
        if !dropShelfManager.hasItems {
            dropShelfManager.addDemoItem()
        }
        stateManager.forceState(.shelfExpanded)
    }
    
    @objc private func addDemoFile() {
        dropShelfManager.addDemoItem()
        stateManager.forceState(.shelfExpanded)
    }
    
    @objc private func clearShelf() {
        dropShelfManager.clearAll()
        stateManager.revertToDefaultState()
    }
    
    // MARK: - Actions
    
    @objc private func toggleDemoPlayer() {
        if nowPlayingManager.isDemoMode {
            nowPlayingManager.disableDemoMode()
        } else {
            nowPlayingManager.enableDemoMode()
        }
    }
    
    @objc private func nextDemoTrack() {
        if !nowPlayingManager.isDemoMode {
            nowPlayingManager.enableDemoMode()
        } else {
            nowPlayingManager.nextTrack()
        }
    }
    
    @objc private func simulateVolUp() {
        let newVol = min(1.0, audioMonitor.volume + 0.10)
        audioMonitor.setVolume(newVol)
    }
    
    @objc private func simulateVolDown() {
        let newVol = max(0.0, audioMonitor.volume - 0.10)
        audioMonitor.setVolume(newVol)
    }
    
    @objc private func simulateMuteToggle() {
        stateManager.triggerVolumeHUD(level: audioMonitor.volume, isMuted: !audioMonitor.isMuted)
    }
    
    @objc private func simulateBrightUp() {
        brightnessMonitor.stepBrightness(by: 0.10)
    }
    
    @objc private func simulateBrightDown() {
        brightnessMonitor.stepBrightness(by: -0.10)
    }
    
    @objc private func toggleExpanded() {
        stateManager.toggleExpanded()
    }
    
    @objc private func repositionNotch() {
        NotchWindowController.shared.repositionWindow()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
