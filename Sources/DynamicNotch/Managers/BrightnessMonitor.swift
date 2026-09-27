import Foundation
import CoreGraphics
import IOKit

@MainActor
public final class BrightnessMonitor: ObservableObject {
    public static let shared = BrightnessMonitor()
    
    @Published public var brightness: Float = 0.75
    public var onBrightnessChanged: ((Float) -> Void)?
    
    // Dynamic binding to private DisplayServices functions
    private typealias DisplayServicesGetLinearBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DisplayServicesSetLinearBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    
    private var getLinearBrightness: DisplayServicesGetLinearBrightnessFunc?
    private var setLinearBrightness: DisplayServicesSetLinearBrightnessFunc?
    
    private var monitorTimer: Timer?
    private var lastObservedBrightness: Float = 0.75
    
    private init() {
        loadDisplayServices()
        readCurrentBrightness()
        self.lastObservedBrightness = self.brightness
        startMonitoring()
    }
    
    deinit {
        monitorTimer?.invalidate()
    }
    
    private func loadDisplayServices() {
        let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
        if let handle = handle {
            if let getSym = dlsym(handle, "DisplayServicesGetLinearBrightness") {
                getLinearBrightness = unsafeBitCast(getSym, to: DisplayServicesGetLinearBrightnessFunc.self)
            }
            if let setSym = dlsym(handle, "DisplayServicesSetLinearBrightness") {
                setLinearBrightness = unsafeBitCast(setSym, to: DisplayServicesSetLinearBrightnessFunc.self)
            }
        }
    }
    
    public func startMonitoring() {
        monitorTimer?.invalidate()
        // Lightweight check every 0.15s: uses virtually 0% CPU, instantly detects keyboard brightness keys
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollBrightnessChange()
            }
        }
    }
    
    private func pollBrightnessChange() {
        let current = getCurrentDisplayBrightness()
        if abs(current - lastObservedBrightness) > 0.008 {
            self.lastObservedBrightness = current
            self.brightness = current
            onBrightnessChanged?(current)
        }
    }
    
    public func readCurrentBrightness() {
        self.brightness = getCurrentDisplayBrightness()
        self.lastObservedBrightness = self.brightness
    }
    
    private func getCurrentDisplayBrightness() -> Float {
        let mainDisplay = CGMainDisplayID()
        var current: Float = 0.75
        
        if let getBrightness = getLinearBrightness {
            let status = getBrightness(mainDisplay, &current)
            if status == 0 {
                return max(0.0, min(1.0, current))
            }
        }
        
        // Fallback via IOKit
        var iterator = io_iterator_t()
        let matching = IOServiceMatching("IODisplayConnect")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        if result == kIOReturnSuccess {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                var br: Float = 0
                let key = CFStringCreateWithCString(kCFAllocatorDefault, "brightness", CFStringBuiltInEncodings.UTF8.rawValue)
                if IODisplayGetFloatParameter(service, 0, key, &br) == kIOReturnSuccess {
                    IOObjectRelease(service)
                    IOObjectRelease(iterator)
                    return max(0.0, min(1.0, br))
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        
        return self.brightness
    }
    
    public func setBrightness(_ value: Float) {
        let clamped = max(0.0, min(1.0, value))
        self.brightness = clamped
        self.lastObservedBrightness = clamped
        let mainDisplay = CGMainDisplayID()
        
        if let setBrightnessFunc = setLinearBrightness {
            _ = setBrightnessFunc(mainDisplay, clamped)
        }
        
        onBrightnessChanged?(clamped)
    }
    
    public func stepBrightness(by delta: Float) {
        setBrightness(brightness + delta)
    }
}
