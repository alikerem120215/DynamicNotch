import SwiftUI

/// Custom shape that matches the Apple MacBook Notch curvature or smooth pill
public struct NotchShape: Shape {
    public var cornerRadius: CGFloat = 16
    public var topEarRadius: CGFloat = 8
    public var hasPhysicalNotch: Bool = true
    
    public var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let r = min(cornerRadius, height / 2.0)
        let earR = min(topEarRadius, 10.0)
        
        if hasPhysicalNotch {
            // Attached to the top screen bezel with top ear outer curves
            path.move(to: CGPoint(x: 0, y: 0))
            
            // Top left ear curve
            path.addQuadCurve(
                to: CGPoint(x: earR, y: earR),
                control: CGPoint(x: earR, y: 0)
            )
            
            // Left edge
            path.addLine(to: CGPoint(x: earR, y: height - r))
            
            // Bottom left corner
            path.addArc(
                center: CGPoint(x: earR + r, y: height - r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(90),
                clockwise: true
            )
            
            // Bottom edge
            path.addLine(to: CGPoint(x: width - earR - r, y: height))
            
            // Bottom right corner
            path.addArc(
                center: CGPoint(x: width - earR - r, y: height - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle: .degrees(0),
                clockwise: true
            )
            
            // Right edge
            path.addLine(to: CGPoint(x: width - earR, y: earR))
            
            // Top right ear curve
            path.addQuadCurve(
                to: CGPoint(x: width, y: 0),
                control: CGPoint(x: width - earR, y: 0)
            )
            
            path.closeSubpath()
        } else {
            // Floating pill (rounded rectangle) for non-notch / external displays
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: r, height: r),
                style: .continuous
            )
        }
        
        return path
    }
}
