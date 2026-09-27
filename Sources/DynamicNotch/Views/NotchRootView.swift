import SwiftUI
import UniformTypeIdentifiers

@MainActor
public struct NotchRootView: View {
    @ObservedObject public var stateManager: NotchStateManager
    @ObservedObject public var nowPlaying: NowPlayingManager
    @ObservedObject public var shelfManager: DropShelfManager
    
    private let geometryHelper = ScreenGeometryHelper.shared
    
    public init(
        stateManager: NotchStateManager,
        nowPlaying: NowPlayingManager,
        shelfManager: DropShelfManager
    ) {
        self.stateManager = stateManager
        self.nowPlaying = nowPlaying
        self.shelfManager = shelfManager
    }
    
    public var body: some View {
        let screenInfo = geometryHelper.getNotchInfo(for: NSScreen.main)
        let baseNotchWidth = screenInfo.physicalNotchRect.width
        let baseNotchHeight = screenInfo.physicalNotchRect.height
        let hasNotch = screenInfo.hasPhysicalNotch
        
        let currentDimensions = calculateDimensions(
            state: stateManager.currentState,
            baseWidth: baseNotchWidth,
            baseHeight: baseNotchHeight,
            hasNotch: hasNotch
        )
        
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // Background Notch Shape (fits physical notch or smooth pill)
                NotchShape(
                    cornerRadius: currentCornerRadius(for: stateManager.currentState),
                    topEarRadius: 8,
                    hasPhysicalNotch: hasNotch
                )
                .fill(Color.black)
                .overlay(
                    NotchShape(
                        cornerRadius: currentCornerRadius(for: stateManager.currentState),
                        topEarRadius: 8,
                        hasPhysicalNotch: hasNotch
                    )
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04),
                                Color.black.opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
                )
                .shadow(
                    color: Color.black.opacity(stateManager.currentState.isExpanded ? 0.5 : 0.25),
                    radius: stateManager.currentState.isExpanded ? 16 : 4,
                    x: 0,
                    y: stateManager.currentState.isExpanded ? 8 : 2
                )
                
                // Content Switcher
                VStack(spacing: 0) {
                    switch stateManager.currentState {
                    case .idle:
                        Color.clear
                            .frame(height: baseNotchHeight)
                        
                    case .mediaCompact:
                        MediaCompactView(
                            track: nowPlaying.currentTrack,
                            notchWidth: baseNotchWidth
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        
                    case .shelfCompact:
                        ShelfCompactView(
                            itemCount: shelfManager.itemCount,
                            notchWidth: baseNotchWidth
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        
                    case .mediaExpanded:
                        VStack(spacing: 0) {
                            if hasNotch {
                                Color.clear.frame(height: baseNotchHeight)
                            }
                            MediaExpandedView(
                                track: nowPlaying.currentTrack,
                                onPlayPause: { nowPlaying.togglePlayPause() },
                                onNext: { nowPlaying.nextTrack() },
                                onPrevious: { nowPlaying.previousTrack() },
                                onSeek: { pos in nowPlaying.seek(to: pos) }
                            )
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        
                    case .shelfExpanded:
                        VStack(spacing: 0) {
                            if hasNotch {
                                Color.clear.frame(height: baseNotchHeight)
                            }
                            NotchShelfView(
                                shelfManager: shelfManager,
                                onClose: { stateManager.revertToDefaultState() }
                            )
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        
                    case .dropTargetActive:
                        VStack(spacing: 0) {
                            if hasNotch {
                                Color.clear.frame(height: baseNotchHeight)
                            }
                            DropTargetBannerView()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        
                    case .volumeHUD(let level, let isMuted):
                        // Essential fix: Render below physical camera cutout
                        VStack(spacing: 0) {
                            if hasNotch {
                                Color.clear.frame(height: baseNotchHeight)
                            }
                            IndicatorHUDView(kind: .volume(level: level, isMuted: isMuted))
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        
                    case .brightnessHUD(let level):
                        // Essential fix: Render below physical camera cutout
                        VStack(spacing: 0) {
                            if hasNotch {
                                Color.clear.frame(height: baseNotchHeight)
                            }
                            IndicatorHUDView(kind: .brightness(level: level))
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    }
                }
                .frame(width: currentDimensions.width, height: currentDimensions.height)
                .clipped()
            }
            .frame(width: currentDimensions.width, height: currentDimensions.height)
            .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0), value: stateManager.currentState)
            .onTapGesture {
                if shelfManager.hasItems || nowPlaying.isMusicActive {
                    stateManager.toggleExpanded()
                }
            }
            // SwiftUI drag-and-drop target
            .onDrop(of: [.fileURL, .item], isTargeted: $stateManager.isDragOver) { providers in
                handleSwiftUIDrop(providers: providers)
                return true
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Drop Handling
    
    private func handleSwiftUIDrop(providers: [NSItemProvider]) {
        var droppedURLs: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    defer { group.leave() }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        droppedURLs.append(url)
                    } else if let url = item as? URL {
                        droppedURLs.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !droppedURLs.isEmpty {
                self.stateManager.handleFilesDropped(droppedURLs)
            }
        }
    }
    
    // MARK: - Dimension Calculations
    
    private func calculateDimensions(
        state: NotchState,
        baseWidth: CGFloat,
        baseHeight: CGFloat,
        hasNotch: Bool
    ) -> CGSize {
        let notchH = hasNotch ? baseHeight : 0
        
        switch state {
        case .idle:
            return CGSize(
                width: hasNotch ? baseWidth : 160,
                height: hasNotch ? baseHeight : 32
            )
        case .mediaCompact:
            return CGSize(
                width: max(baseWidth + 140, 260),
                height: max(baseHeight, 34)
            )
        case .shelfCompact:
            return CGSize(
                width: max(baseWidth + 130, 250),
                height: max(baseHeight, 34)
            )
        case .mediaExpanded:
            return CGSize(
                width: 440,
                height: notchH + 175
            )
        case .shelfExpanded:
            return CGSize(
                width: 480,
                height: notchH + 155
            )
        case .dropTargetActive:
            return CGSize(
                width: max(baseWidth + 180, 360),
                height: notchH + 68
            )
        case .volumeHUD, .brightnessHUD:
            return CGSize(
                width: max(baseWidth + 120, 300),
                // Drops down below physical camera cutout
                height: notchH + 42
            )
        }
    }
    
    private func currentCornerRadius(for state: NotchState) -> CGFloat {
        switch state {
        case .idle:
            return 14
        case .mediaCompact, .shelfCompact:
            return 17
        case .mediaExpanded, .shelfExpanded:
            return 26
        case .dropTargetActive:
            return 22
        case .volumeHUD, .brightnessHUD:
            return 20
        }
    }
}
