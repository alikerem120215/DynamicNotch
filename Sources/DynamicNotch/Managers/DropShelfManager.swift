import AppKit
import UniformTypeIdentifiers
import QuickLookThumbnailing

@MainActor
public final class DropShelfManager: ObservableObject {
    public static let shared = DropShelfManager()
    
    @Published public private(set) var items: [ShelfItem] = []
    @Published public var isDragOverNotch: Bool = false
    
    private let storageDirectory: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.storageDirectory = appSupport.appendingPathComponent("DynamicNotch/Shelf", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
    
    public var hasItems: Bool {
        !items.isEmpty
    }
    
    public var itemCount: Int {
        items.count
    }
    
    public func addFiles(urls: [URL]) {
        for url in urls {
            // If the item is already on shelf, don't duplicate
            guard !items.contains(where: { $0.url.path == url.path }) else { continue }
            
            // Create local cached copy if needed or use reference
            let targetURL = url
            let item = ShelfItem(url: targetURL)
            items.insert(item, at: 0)
            
            // Generate asynchronous high-res thumbnail
            generateThumbnail(for: item)
        }
    }
    
    private func generateThumbnail(for item: ShelfItem) {
        let size = CGSize(width: 140, height: 140)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(
            fileAt: item.url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { [weak self] (representation, type, error) in
            if let rep = representation {
                let thumbImage = rep.nsImage
                DispatchQueue.main.async {
                    if let index = self?.items.firstIndex(where: { $0.id == item.id }) {
                        self?.items[index] = ShelfItem(
                            id: item.id,
                            url: item.url,
                            thumbnail: thumbImage
                        )
                    }
                }
            }
        }
    }
    
    public func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    public func clearAll() {
        items.removeAll()
    }
    
    public func openItem(_ item: ShelfItem) {
        NSWorkspace.shared.open(item.url)
    }
    
    public func revealInFinder(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
    
    // Quick Demo items for testing
    public func addDemoItem() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Demo_Photo.png")
        if !FileManager.default.fileExists(atPath: tempURL.path) {
            let img = NSImage(size: NSSize(width: 200, height: 200))
            img.lockFocus()
            NSColor.systemBlue.setFill()
            NSRect(x: 0, y: 0, width: 200, height: 200).fill()
            img.unlockFocus()
            if let tiff = img.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: tempURL)
            }
        }
        addFiles(urls: [tempURL])
    }
}
