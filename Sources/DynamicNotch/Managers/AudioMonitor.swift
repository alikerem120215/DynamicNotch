import Foundation
import CoreAudio
import AudioToolbox

@MainActor
public final class AudioMonitor: ObservableObject {
    public static let shared = AudioMonitor()
    
    @Published public var volume: Float = 0.5
    @Published public var isMuted: Bool = false
    
    public var onVolumeChanged: ((Float, Bool) -> Void)?
    
    private var defaultOutputDeviceId: AudioObjectID = kAudioObjectUnknown
    private var isObserving: Bool = false
    
    private var deviceListenerBlock: AudioObjectPropertyListenerBlock?
    private var volumeListenerBlock: AudioObjectPropertyListenerBlock?
    private var muteListenerBlock: AudioObjectPropertyListenerBlock?
    
    private init() {
        setupListener()
    }
    
    deinit {
        // Cleanup CoreAudio listeners
        if defaultOutputDeviceId != kAudioObjectUnknown {
            if let volBlock = volumeListenerBlock {
                var volAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                    mScope: kAudioObjectPropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                AudioObjectRemovePropertyListenerBlock(defaultOutputDeviceId, &volAddress, DispatchQueue.main, volBlock)
                
                var altVolAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioObjectPropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                AudioObjectRemovePropertyListenerBlock(defaultOutputDeviceId, &altVolAddress, DispatchQueue.main, volBlock)
            }
            if let muteBlock = muteListenerBlock {
                var muteAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyMute,
                    mScope: kAudioObjectPropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                AudioObjectRemovePropertyListenerBlock(defaultOutputDeviceId, &muteAddress, DispatchQueue.main, muteBlock)
            }
        }
        if let deviceBlock = deviceListenerBlock {
            var propertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                DispatchQueue.main,
                deviceBlock
            )
        }
    }
    
    private func setupListener() {
        updateDefaultOutputDevice()
        addDefaultDeviceListener()
        addOutputListeners()
        readCurrentVolumeAndMute()
    }
    
    // MARK: - CoreAudio Listeners
    
    private func updateDefaultOutputDevice() {
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        
        if status == noErr {
            self.defaultOutputDeviceId = deviceID
        }
    }
    
    private func addDefaultDeviceListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.handleDeviceChange()
            }
        }
        self.deviceListenerBlock = block
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            block
        )
    }
    
    private func handleDeviceChange() {
        removeOutputListeners()
        updateDefaultOutputDevice()
        addOutputListeners()
        readCurrentVolumeAndMute()
    }
    
    private func addOutputListeners() {
        guard defaultOutputDeviceId != kAudioObjectUnknown else { return }
        
        // 1. Volume listener
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if !AudioObjectHasProperty(defaultOutputDeviceId, &volAddress) {
            volAddress.mSelector = kAudioDevicePropertyVolumeScalar
        }
        
        let volBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.readCurrentVolumeAndMute(notify: true)
            }
        }
        self.volumeListenerBlock = volBlock
        
        AudioObjectAddPropertyListenerBlock(
            defaultOutputDeviceId,
            &volAddress,
            DispatchQueue.main,
            volBlock
        )
        
        // 2. Mute listener
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let muteBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.readCurrentVolumeAndMute(notify: true)
            }
        }
        self.muteListenerBlock = muteBlock
        
        AudioObjectAddPropertyListenerBlock(
            defaultOutputDeviceId,
            &muteAddress,
            DispatchQueue.main,
            muteBlock
        )
        
        isObserving = true
    }
    
    private func removeOutputListeners() {
        guard defaultOutputDeviceId != kAudioObjectUnknown else { return }
        
        if let volBlock = volumeListenerBlock {
            var volAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(defaultOutputDeviceId, &volAddress, DispatchQueue.main, volBlock)
            
            var altVolAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(defaultOutputDeviceId, &altVolAddress, DispatchQueue.main, volBlock)
        }
        
        if let muteBlock = muteListenerBlock {
            var muteAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(defaultOutputDeviceId, &muteAddress, DispatchQueue.main, muteBlock)
        }
    }
    
    private func removeListeners() {
        removeOutputListeners()
        if let deviceBlock = deviceListenerBlock {
            var propertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                DispatchQueue.main,
                deviceBlock
            )
        }
    }
    
    // MARK: - Reading & Writing Values
    
    public func readCurrentVolumeAndMute(notify: Bool = false) {
        guard defaultOutputDeviceId != kAudioObjectUnknown else { return }
        
        var currentVol: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if !AudioObjectHasProperty(defaultOutputDeviceId, &volAddress) {
            volAddress.mSelector = kAudioDevicePropertyVolumeScalar
        }
        
        let volStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceId,
            &volAddress,
            0,
            nil,
            &size,
            &currentVol
        )
        
        if volStatus == noErr {
            self.volume = currentVol
        }
        
        var isMuteInt: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let muteStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceId,
            &muteAddress,
            0,
            nil,
            &muteSize,
            &isMuteInt
        )
        
        if muteStatus == noErr {
            self.isMuted = (isMuteInt != 0)
        }
        
        if notify {
            onVolumeChanged?(self.volume, self.isMuted)
        }
    }
    
    public func setVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        var vol = Float32(clamped)
        let size = UInt32(MemoryLayout<Float32>.size)
        
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if !AudioObjectHasProperty(defaultOutputDeviceId, &volAddress) {
            volAddress.mSelector = kAudioDevicePropertyVolumeScalar
        }
        
        AudioObjectSetPropertyData(
            defaultOutputDeviceId,
            &volAddress,
            0,
            nil,
            size,
            &vol
        )
        
        self.volume = clamped
        onVolumeChanged?(self.volume, self.isMuted)
    }
}
