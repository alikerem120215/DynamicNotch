import AppKit

public enum MediaSource: String, Sendable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case system = "System Media"
    case demo = "Demo Player"
}

public struct MediaTrack: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var album: String
    public var duration: TimeInterval
    public var position: TimeInterval
    public var isPlaying: Bool
    public var source: MediaSource
    public var artworkImage: NSImage?
    
    public init(
        title: String = "No Media Playing",
        artist: String = "Unknown Artist",
        album: String = "",
        duration: TimeInterval = 0,
        position: TimeInterval = 0,
        isPlaying: Bool = false,
        source: MediaSource = .system,
        artworkImage: NSImage? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.position = position
        self.isPlaying = isPlaying
        self.source = source
        self.artworkImage = artworkImage
    }
    
    public static func == (lhs: MediaTrack, rhs: MediaTrack) -> Bool {
        return lhs.title == rhs.title &&
               lhs.artist == rhs.artist &&
               lhs.album == rhs.album &&
               lhs.duration == rhs.duration &&
               lhs.position == rhs.position &&
               lhs.isPlaying == rhs.isPlaying &&
               lhs.source == rhs.source
    }
    
    public var formattedPosition: String {
        formatTime(position)
    }
    
    public var formattedRemaining: String {
        let remaining = max(0, duration - position)
        return "-\(formatTime(remaining))"
    }
    
    public var progressRatio: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0.0), 1.0)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
