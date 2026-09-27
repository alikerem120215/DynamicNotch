import Foundation

/// Represents the visual presentation state of the Dynamic Notch
public enum NotchState: Equatable {
    /// Resting state, fits exactly to the physical notch or small virtual island
    case idle
    
    /// Compact media state showing mini album art on left, mini equalizer on right
    case mediaCompact
    
    /// Fully expanded media controller card on hover/click
    case mediaExpanded
    
    /// Compact shelf indicator when files are stored in the notch
    case shelfCompact
    
    /// Fully expanded file shelf / drawer allowing drag-out and file management
    case shelfExpanded
    
    /// Visual state when a file is actively being dragged over the notch
    case dropTargetActive
    
    /// Volume adjustment HUD
    case volumeHUD(level: Float, isMuted: Bool)
    
    /// Brightness adjustment HUD
    case brightnessHUD(level: Float)
    
    public var isExpanded: Bool {
        switch self {
        case .mediaExpanded, .shelfExpanded:
            return true
        default:
            return false
        }
    }
    
    public var isHUD: Bool {
        switch self {
        case .volumeHUD, .brightnessHUD:
            return true
        default:
            return false
        }
    }
}
