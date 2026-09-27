import AppKit
import CoreGraphics

public final class MediaKeyTapManager: @unchecked Sendable {
    public static let shared = MediaKeyTapManager()
    
    public var onVolumeUp: (() -> Void)?
    public var onVolumeDown: (() -> Void)?
    public var onMuteToggle: (() -> Void)?
    public var onBrightnessUp: (() -> Void)?
    public var onBrightnessDown: (() -> Void)?
    public var onPlayPause: (() -> Void)?
    public var onNextTrack: (() -> Void)?
    public var onPreviousTrack: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private init() {}
    
    public func start() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        guard isTrusted else {
            print("[MediaKeyTapManager] Accessibility prompt displayed or not granted.")
            return
        }
        
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << 0xE) // 0xE is NSEventType.systemDefined
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let manager = Unmanaged<MediaKeyTapManager>.fromOpaque(refcon).takeUnretainedValue()
            
            if event.type.rawValue == 0xE { // NSEventType.systemDefined
                if let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 {
                    let data1 = Int(nsEvent.data1)
                    let keyCode = Int32((data1 & 0xFFFF0000) >> 16)
                    let keyFlags = (data1 & 0x0000FFFF)
                    let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
                    
                    if keyState {
                        DispatchQueue.main.async {
                            switch keyCode {
                            case 0: // NX_KEYTYPE_SOUND_UP
                                manager.onVolumeUp?()
                            case 1: // NX_KEYTYPE_SOUND_DOWN
                                manager.onVolumeDown?()
                            case 7: // NX_KEYTYPE_MUTE
                                manager.onMuteToggle?()
                            case 2: // NX_KEYTYPE_BRIGHTNESS_UP
                                manager.onBrightnessUp?()
                            case 3: // NX_KEYTYPE_BRIGHTNESS_DOWN
                                manager.onBrightnessDown?()
                            case 16: // NX_KEYTYPE_PLAY
                                manager.onPlayPause?()
                            case 19: // NX_KEYTYPE_NEXT
                                manager.onNextTrack?()
                            case 20: // NX_KEYTYPE_PREVIOUS
                                manager.onPreviousTrack?()
                            default:
                                break
                            }
                        }
                    }
                }
            }
            return Unmanaged.passRetained(event)
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPtr
        ) else {
            print("[MediaKeyTapManager] Failed to create CGEventTap")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
    }
}
