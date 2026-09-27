import SwiftUI

public struct MediaExpandedView: View {
    public let track: MediaTrack
    public var onPlayPause: () -> Void
    public var onNext: () -> Void
    public var onPrevious: () -> Void
    public var onSeek: (TimeInterval) -> Void
    
    public init(
        track: MediaTrack,
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onSeek: @escaping (TimeInterval) -> Void
    ) {
        self.track = track
        self.onPlayPause = onPlayPause
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.onSeek = onSeek
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Upper row: Artwork, Title/Artist, Source Badge
            HStack(spacing: 14) {
                // Album Artwork with subtle glow
                ZStack {
                    if let artwork = track.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.25, blue: 0.45),
                                        Color(red: 0.55, green: 0.15, blue: 0.90)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Track Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        MarqueeText(
                            text: track.title,
                            font: .system(size: 15, weight: .bold, design: .rounded),
                            color: .white
                        )
                        
                        Spacer()
                        
                        // Source badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(track.source == .spotify ? Color.green : Color.pink)
                                .frame(width: 6, height: 6)
                            Text(track.source.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    
                    Text(track.artist + (track.album.isEmpty ? "" : " — \(track.album)"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // Middle: Scrubber timeline
            VStack(spacing: 4) {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let progress = CGFloat(track.progressRatio)
                    
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 4)
                        
                        // Active track
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        track.source == .spotify ? Color(red: 0.18, green: 0.85, blue: 0.55) : Color(red: 0.98, green: 0.32, blue: 0.55),
                                        Color.white
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, width * progress), height: 4)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let ratio = max(0.0, min(1.0, Double(value.location.x / width)))
                                onSeek(ratio * track.duration)
                            }
                    )
                }
                .frame(height: 8)
                
                // Time labels
                HStack {
                    Text(track.formattedPosition)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text(track.formattedRemaining)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            
            // Bottom: Controls (Prev, Play/Pause, Next)
            HStack(spacing: 28) {
                // Prev button
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Play / Pause prominent button
                Button(action: onPlayPause) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.white.opacity(0.2), radius: 4, x: 0, y: 1)
                        
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .offset(x: track.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Next button
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 12)
        }
        .frame(width: 400)
    }
}
