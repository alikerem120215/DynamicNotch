import AppKit
import Foundation
import Combine

@MainActor
public final class NowPlayingManager: ObservableObject {
    public static let shared = NowPlayingManager()
    
    @Published public var currentTrack: MediaTrack = MediaTrack()
    @Published public var isMusicActive: Bool = false
    @Published public var isDemoMode: Bool = false
    
    private var progressTimer: AnyCancellable?
    private var notificationObservers: [NSObjectProtocol] = []
    
    private init() {
        setupObservers()
        startProgressTimer()
    }
    
    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Notification Observers
    
    private func setupObservers() {
        let musicObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAppleMusicNotification(notification)
            }
        }
        
        let spotifyObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleSpotifyNotification(notification)
            }
        }
        
        notificationObservers.append(contentsOf: [musicObserver, spotifyObserver])
        
        // Initial check for running players
        checkRunningPlayers()
    }
    
    public func checkRunningPlayers() {
        if isAppRunning(bundleId: "com.apple.Music") {
            queryAppleMusic()
        } else if isAppRunning(bundleId: "com.spotify.client") {
            querySpotify()
        }
    }
    
    private func isAppRunning(bundleId: String) -> Bool {
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
    }
    
    // MARK: - Apple Music
    
    private func handleAppleMusicNotification(_ notification: Notification) {
        guard !isDemoMode else { return }
        guard let userInfo = notification.userInfo else { return }
        
        let playerState = userInfo["Player State"] as? String ?? ""
        let isPlaying = playerState == "Playing"
        
        if !isPlaying && playerState == "Stopped" {
            self.isMusicActive = false
            self.currentTrack.isPlaying = false
            return
        }
        
        let name = userInfo["Name"] as? String ?? "Unknown Title"
        let artist = userInfo["Artist"] as? String ?? "Unknown Artist"
        let album = userInfo["Album"] as? String ?? ""
        let duration = (userInfo["Total Time"] as? Double ?? 0) / 1000.0
        
        let track = MediaTrack(
            title: name,
            artist: artist,
            album: album,
            duration: duration > 0 ? duration : 210,
            position: 0,
            isPlaying: isPlaying,
            source: .appleMusic,
            artworkImage: nil
        )
        
        self.currentTrack = track
        self.isMusicActive = isPlaying
        
        // Fetch artwork and current position asynchronously
        fetchAppleMusicDetails()
    }
    
    private func fetchAppleMusicDetails() {
        Task.detached(priority: .background) {
            let script = """
            tell application "Music"
                if it is running then
                    set trackPos to player position
                    set trackDur to duration of current track
                    set artData to ""
                    try
                        set artData to raw data of artwork 1 of current track
                    end try
                    return {trackPos, trackDur, artData}
                end if
            end tell
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                if error == nil && result.numberOfItems >= 2 {
                    let pos = result.atIndex(1)?.doubleValue ?? 0
                    let dur = result.atIndex(2)?.doubleValue ?? 0
                    
                    let image: NSImage?
                    if result.numberOfItems >= 3, let dataDesc = result.atIndex(3) {
                        let rawData = dataDesc.data
                        image = NSImage(data: rawData)
                    } else {
                        image = nil
                    }
                    
                    await MainActor.run {
                        self.currentTrack.position = pos
                        if dur > 0 { self.currentTrack.duration = dur }
                        if let image = image {
                            self.currentTrack.artworkImage = image
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Spotify
    
    private func handleSpotifyNotification(_ notification: Notification) {
        guard !isDemoMode else { return }
        guard let userInfo = notification.userInfo else { return }
        
        let playerState = userInfo["Player State"] as? String ?? ""
        let isPlaying = playerState == "Playing" || playerState == "kPSP"
        
        let name = userInfo["Name"] as? String ?? "Unknown Title"
        let artist = userInfo["Artist"] as? String ?? "Unknown Artist"
        let album = userInfo["Album"] as? String ?? ""
        let duration = (userInfo["Duration"] as? Double ?? 0) / 1000.0
        let position = (userInfo["Playback Position"] as? Double ?? 0)
        
        let track = MediaTrack(
            title: name,
            artist: artist,
            album: album,
            duration: duration > 0 ? duration : 180,
            position: position,
            isPlaying: isPlaying,
            source: .spotify,
            artworkImage: nil
        )
        
        self.currentTrack = track
        self.isMusicActive = isPlaying
        
        if let artworkUrlString = userInfo["Artwork URL"] as? String,
           let url = URL(string: artworkUrlString) {
            fetchRemoteArtwork(url: url)
        }
    }
    
    private func fetchRemoteArtwork(url: URL) {
        Task.detached(priority: .background) {
            if let data = try? Data(contentsOf: url),
               let image = NSImage(data: data) {
                await MainActor.run {
                    self.currentTrack.artworkImage = image
                }
            }
        }
    }
    
    private func queryAppleMusic() {
        Task.detached(priority: .background) {
            let script = """
            tell application "Music"
                if it is running then
                    set pState to (player state as string)
                    set tName to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDur to duration of current track
                    set tPos to player position
                    return {pState, tName, tArtist, tAlbum, tDur, tPos}
                end if
            end tell
            """
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                if error == nil && result.numberOfItems >= 6 {
                    let state = result.atIndex(1)?.stringValue ?? ""
                    let isPlaying = state == "playing"
                    let name = result.atIndex(2)?.stringValue ?? ""
                    let artist = result.atIndex(3)?.stringValue ?? ""
                    let album = result.atIndex(4)?.stringValue ?? ""
                    let dur = result.atIndex(5)?.doubleValue ?? 0
                    let pos = result.atIndex(6)?.doubleValue ?? 0
                    
                    await MainActor.run {
                        self.currentTrack = MediaTrack(
                            title: name,
                            artist: artist,
                            album: album,
                            duration: dur,
                            position: pos,
                            isPlaying: isPlaying,
                            source: .appleMusic,
                            artworkImage: nil
                        )
                        self.isMusicActive = isPlaying
                    }
                }
            }
        }
    }
    
    private func querySpotify() {
        Task.detached(priority: .background) {
            let script = """
            tell application "Spotify"
                if it is running then
                    set pState to (player state as string)
                    set tName to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDur to (duration of current track) / 1000
                    set tPos to player position
                    set artUrl to artwork url of current track
                    return {pState, tName, tArtist, tAlbum, tDur, tPos, artUrl}
                end if
            end tell
            """
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                if error == nil && result.numberOfItems >= 6 {
                    let state = result.atIndex(1)?.stringValue ?? ""
                    let isPlaying = state == "playing"
                    let name = result.atIndex(2)?.stringValue ?? ""
                    let artist = result.atIndex(3)?.stringValue ?? ""
                    let album = result.atIndex(4)?.stringValue ?? ""
                    let dur = result.atIndex(5)?.doubleValue ?? 0
                    let pos = result.atIndex(6)?.doubleValue ?? 0
                    let artUrl = result.numberOfItems >= 7 ? result.atIndex(7)?.stringValue : nil
                    
                    await MainActor.run {
                        self.currentTrack = MediaTrack(
                            title: name,
                            artist: artist,
                            album: album,
                            duration: dur,
                            position: pos,
                            isPlaying: isPlaying,
                            source: .spotify,
                            artworkImage: nil
                        )
                        self.isMusicActive = isPlaying
                        if let artUrl = artUrl, let url = URL(string: artUrl) {
                            self.fetchRemoteArtwork(url: url)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Media Controls
    
    public func togglePlayPause() {
        if isDemoMode {
            currentTrack.isPlaying.toggle()
            isMusicActive = currentTrack.isPlaying
            return
        }
        
        let appName = currentTrack.source == .spotify ? "Spotify" : "Music"
        executeScript("""
        tell application "\(appName)"
            playpause
        end tell
        """)
        currentTrack.isPlaying.toggle()
        isMusicActive = currentTrack.isPlaying
    }
    
    public func nextTrack() {
        if isDemoMode {
            loadNextDemoTrack()
            return
        }
        let appName = currentTrack.source == .spotify ? "Spotify" : "Music"
        executeScript("""
        tell application "\(appName)"
            next track
        end tell
        """)
    }
    
    public func previousTrack() {
        if isDemoMode {
            currentTrack.position = 0
            return
        }
        let appName = currentTrack.source == .spotify ? "Spotify" : "Music"
        executeScript("""
        tell application "\(appName)"
            previous track
        end tell
        """)
    }
    
    public func seek(to position: TimeInterval) {
        currentTrack.position = position
        guard !isDemoMode else { return }
        
        let appName = currentTrack.source == .spotify ? "Spotify" : "Music"
        executeScript("""
        tell application "\(appName)"
            set player position to \(position)
        end tell
        """)
    }
    
    private func executeScript(_ source: String) {
        Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            if let script = NSAppleScript(source: source) {
                script.executeAndReturnError(&error)
            }
        }
    }
    
    // MARK: - Progress Timer
    
    private func startProgressTimer() {
        progressTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.currentTrack.isPlaying else { return }
                if self.currentTrack.position < self.currentTrack.duration {
                    self.currentTrack.position += 1.0
                }
            }
    }
    
    // MARK: - Demo Mode
    
    public func enableDemoMode() {
        isDemoMode = true
        isMusicActive = true
        currentTrack = MediaTrack(
            title: "Starboy (feat. Daft Punk)",
            artist: "The Weeknd",
            album: "Starboy",
            duration: 230,
            position: 45,
            isPlaying: true,
            source: .demo,
            artworkImage: createDemoArtwork()
        )
    }
    
    public func disableDemoMode() {
        isDemoMode = false
        isMusicActive = false
        currentTrack = MediaTrack()
        checkRunningPlayers()
    }
    
    private func loadNextDemoTrack() {
        let demoTracks: [(String, String, String, TimeInterval)] = [
            ("Blinding Lights", "The Weeknd", "After Hours", 200),
            ("Get Lucky", "Daft Punk ft. Pharrell", "Random Access Memories", 248),
            ("Midnight City", "M83", "Hurry Up, We're Dreaming", 244),
            ("Instant Destiny", "Tame Impala", "The Slow Rush", 195)
        ]
        let random = demoTracks.randomElement()!
        currentTrack = MediaTrack(
            title: random.0,
            artist: random.1,
            album: random.2,
            duration: random.3,
            position: 0,
            isPlaying: true,
            source: .demo,
            artworkImage: createDemoArtwork(title: random.0)
        )
    }
    
    private func createDemoArtwork(title: String = "Starboy") -> NSImage {
        let size = NSSize(width: 120, height: 120)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Vibrant dark gradient
        let gradient = NSGradient(
            colors: [
                NSColor(red: 0.95, green: 0.25, blue: 0.35, alpha: 1.0),
                NSColor(red: 0.45, green: 0.15, blue: 0.85, alpha: 1.0)
            ]
        )
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        let icon = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
        icon?.isTemplate = false
        icon?.draw(
            in: NSRect(x: 35, y: 35, width: 50, height: 50),
            from: .zero,
            operation: .sourceOver,
            fraction: 0.9
        )
        
        image.unlockFocus()
        return image
    }
}
