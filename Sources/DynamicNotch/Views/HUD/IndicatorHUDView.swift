import SwiftUI

public struct IndicatorHUDView: View {
    public let kind: HUDKind
    
    public var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: kind.iconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            // Interactive Progress Bar
            GeometryReader { proxy in
                let width = proxy.size.width
                let progress = CGFloat(kind.normalizedValue)
                
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 7)
                    
                    // Fill with gradient
                    Capsule()
                        .fill(barGradient)
                        .frame(width: max(7, width * progress), height: 7)
                        .shadow(color: glowColor.opacity(0.4), radius: 4, x: 0, y: 0)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let ratio = max(0.0, min(1.0, Float(value.location.x / width)))
                            handleValueChange(ratio)
                        }
                )
            }
            .frame(height: 14)
            
            // Percentage Text
            Text(isMuted ? "MUTED" : kind.percentageString)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 38)
    }
    
    private func handleValueChange(_ value: Float) {
        switch kind {
        case .volume:
            AudioMonitor.shared.setVolume(value)
        case .brightness:
            BrightnessMonitor.shared.setBrightness(value)
        }
    }
    
    private var isMuted: Bool {
        if case .volume(_, let muted) = kind {
            return muted
        }
        return false
    }
    
    private var iconColor: Color {
        switch kind {
        case .volume(_, let isMuted):
            return isMuted ? Color.red.opacity(0.8) : Color.white
        case .brightness:
            return Color(red: 1.0, green: 0.8, blue: 0.2)
        }
    }
    
    private var barGradient: LinearGradient {
        switch kind {
        case .volume(_, let isMuted):
            if isMuted {
                return LinearGradient(
                    colors: [Color.red.opacity(0.6), Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color.white],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        case .brightness:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.65, blue: 0.1), Color(red: 1.0, green: 0.95, blue: 0.4)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var glowColor: Color {
        switch kind {
        case .volume(_, let isMuted):
            return isMuted ? Color.red : Color.blue
        case .brightness:
            return Color.orange
        }
    }
}
