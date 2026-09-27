import SwiftUI

public struct AudioVisualizerView: View {
    public var isPlaying: Bool
    public var barCount: Int = 4
    public var barColor: Color = Color.green
    public var barWidth: CGFloat = 2.5
    public var maxHeight: CGFloat = 14
    
    public init(
        isPlaying: Bool = true,
        barCount: Int = 4,
        barColor: Color = Color(red: 0.18, green: 0.85, blue: 0.55),
        barWidth: CGFloat = 2.5,
        maxHeight: CGFloat = 14
    ) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self.barColor = barColor
        self.barWidth = barWidth
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.18, paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2.5) {
                ForEach(0..<barCount, id: \.self) { index in
                    let height = computeHeight(index: index, time: date)
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [barColor, barColor.opacity(0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: barWidth,
                            height: isPlaying ? height : 4
                        )
                }
            }
        }
    }
    
    private func computeHeight(index: Int, time: Double) -> CGFloat {
        // Multi-frequency wave formula creating natural equalizer bar bounce
        let speed = 8.0
        let offset = Double(index) * 1.6
        let sin1 = sin(time * speed + offset)
        let cos1 = cos(time * (speed * 0.7) + Double(index) * 0.9)
        let normalized = (sin1 + cos1 + 2.0) / 4.0 // Range 0.0 ... 1.0
        let clamped = max(0.25, min(1.0, normalized))
        return maxHeight * CGFloat(clamped)
    }
}
