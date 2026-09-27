import Foundation

public enum HUDKind: Equatable, Sendable {
    case volume(level: Float, isMuted: Bool)
    case brightness(level: Float)
    
    public var iconName: String {
        switch self {
        case .volume(let level, let isMuted):
            if isMuted || level == 0 {
                return "speaker.slash.fill"
            } else if level < 0.33 {
                return "speaker.wave.1.fill"
            } else if level < 0.66 {
                return "speaker.wave.2.fill"
            } else {
                return "speaker.wave.3.fill"
            }
        case .brightness(let level):
            if level < 0.5 {
                return "sun.min.fill"
            } else {
                return "sun.max.fill"
            }
        }
    }
    
    public var title: String {
        switch self {
        case .volume:
            return "Volume"
        case .brightness:
            return "Brightness"
        }
    }
    
    public var normalizedValue: Float {
        switch self {
        case .volume(let level, let isMuted):
            return isMuted ? 0 : max(0, min(1, level))
        case .brightness(let level):
            return max(0, min(1, level))
        }
    }
    
    public var percentageString: String {
        "\(Int(round(normalizedValue * 100)))%"
    }
}
