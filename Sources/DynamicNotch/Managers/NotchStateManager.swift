import SwiftUI
import Combine

@MainActor
public final class NotchStateManager: ObservableObject {
    public static let shared = NotchStateManager()
    
    @Published public private(set) var currentState: NotchState = .idle
    @Published public var isHovered: Bool = false
    @Published public var isDragOver: Bool = false
    
    private var hudDismissWorkItem: DispatchWorkItem?
    private var hoverDismissWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // 1. Listen to AudioMonitor
        AudioMonitor.shared.onVolumeChanged = { [weak self] level, isMuted in
            Task { @MainActor [weak self] in
                self?.triggerVolumeHUD(level: level, isMuted: isMuted)
            }
        }
        
        // 2. Listen to BrightnessMonitor
        BrightnessMonitor.shared.onBrightnessChanged = { [weak self] level in
            Task { @MainActor [weak self] in
                self?.triggerBrightnessHUD(level: level)
            }
        }
        
        // 3. Listen to NowPlayingManager state
        NowPlayingManager.shared.$isMusicActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.handleMusicActiveStateChanged(isActive)
            }
            .store(in: &cancellables)
        
        // 4. Listen to DropShelfManager changes
        DropShelfManager.shared.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleShelfItemsChanged()
            }
            .store(in: &cancellables)
        
        // 5. Media Key Tap Actions
        setupMediaKeyBindings()
    }
    
    private func setupMediaKeyBindings() {
        let keyManager = MediaKeyTapManager.shared
        keyManager.onVolumeUp = {
            let current = AudioMonitor.shared.volume
            AudioMonitor.shared.setVolume(current + 0.0625)
        }
        keyManager.onVolumeDown = {
            let current = AudioMonitor.shared.volume
            AudioMonitor.shared.setVolume(current - 0.0625)
        }
        keyManager.onBrightnessUp = {
            BrightnessMonitor.shared.stepBrightness(by: 0.0625)
        }
        keyManager.onBrightnessDown = {
            BrightnessMonitor.shared.stepBrightness(by: -0.0625)
        }
        keyManager.onPlayPause = {
            NowPlayingManager.shared.togglePlayPause()
        }
        keyManager.onNextTrack = {
            NowPlayingManager.shared.nextTrack()
        }
        keyManager.onPreviousTrack = {
            NowPlayingManager.shared.previousTrack()
        }
    }
    
    // MARK: - State Transitions
    
    public func triggerVolumeHUD(level: Float, isMuted: Bool) {
        hudDismissWorkItem?.cancel()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.currentState = .volumeHUD(level: level, isMuted: isMuted)
        }
        
        scheduleHUDDismiss()
    }
    
    public func triggerBrightnessHUD(level: Float) {
        hudDismissWorkItem?.cancel()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.currentState = .brightnessHUD(level: level)
        }
        
        scheduleHUDDismiss()
    }
    
    private func scheduleHUDDismiss() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.revertToDefaultState()
        }
        
        hudDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
    }
    
    public func revertToDefaultState() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let hasShelfItems = DropShelfManager.shared.hasItems
            let isMusicActive = NowPlayingManager.shared.isMusicActive
            
            if self.isHovered {
                if hasShelfItems {
                    self.currentState = .shelfExpanded
                } else if isMusicActive {
                    self.currentState = .mediaExpanded
                } else {
                    self.currentState = .idle
                }
            } else {
                if isMusicActive {
                    self.currentState = .mediaCompact
                } else if hasShelfItems {
                    self.currentState = .shelfCompact
                } else {
                    self.currentState = .idle
                }
            }
        }
    }
    
    private func handleMusicActiveStateChanged(_ isActive: Bool) {
        guard !currentState.isHUD && !isDragOver else { return }
        revertToDefaultState()
    }
    
    private func handleShelfItemsChanged() {
        guard !currentState.isHUD && !isDragOver else { return }
        revertToDefaultState()
    }
    
    // MARK: - Mouse Hover & Clicks
    
    public func handleMouseEnter() {
        isHovered = true
        hoverDismissWorkItem?.cancel()
        
        guard !currentState.isHUD && !isDragOver else { return }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if DropShelfManager.shared.hasItems {
                self.currentState = .shelfExpanded
            } else if NowPlayingManager.shared.isMusicActive {
                self.currentState = .mediaExpanded
            }
        }
    }
    
    public func handleMouseExit() {
        isHovered = false
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard !self.currentState.isHUD && !self.isDragOver else { return }
            self.revertToDefaultState()
        }
        
        hoverDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    // MARK: - Drag and Drop Handling
    
    public func handleDragEntered() {
        isDragOver = true
        hudDismissWorkItem?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.currentState = .dropTargetActive
        }
    }
    
    public func handleDragExited() {
        isDragOver = false
        revertToDefaultState()
    }
    
    public func handleFilesDropped(_ urls: [URL]) {
        isDragOver = false
        DropShelfManager.shared.addFiles(urls: urls)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.currentState = .shelfExpanded
        }
    }
    
    public func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if currentState == .shelfExpanded || currentState == .mediaExpanded {
                revertToDefaultState()
            } else {
                if DropShelfManager.shared.hasItems {
                    currentState = .shelfExpanded
                } else if NowPlayingManager.shared.isMusicActive {
                    currentState = .mediaExpanded
                }
            }
        }
    }
    
    public func forceState(_ state: NotchState) {
        hudDismissWorkItem?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.currentState = state
        }
        if state.isHUD {
            scheduleHUDDismiss()
        }
    }
}
