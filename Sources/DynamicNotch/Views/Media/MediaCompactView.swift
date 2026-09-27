import SwiftUI

public struct MediaCompactView: View {
    public let track: MediaTrack
    public let notchWidth: CGFloat
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left Side: Mini Album Artwork
            HStack {
                if let artwork = track.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                Spacer()
            }
            .frame(width: 44)
            .padding(.leading, 8)
            
            // Center Space (reserves space for physical camera / notch center)
            Spacer()
            
            // Right Side: Mini Equalizer Visualizer
            HStack {
                Spacer()
                AudioVisualizerView(
                    isPlaying: track.isPlaying,
                    barCount: 4,
                    barColor: track.source == .spotify ? Color(red: 0.18, green: 0.85, blue: 0.45) : Color(red: 0.98, green: 0.32, blue: 0.45),
                    barWidth: 2.2,
                    maxHeight: 12
                )
            }
            .frame(width: 44)
            .padding(.trailing, 8)
        }
        .frame(height: 32)
    }
}
