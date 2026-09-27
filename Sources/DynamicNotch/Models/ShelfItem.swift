import AppKit
import UniformTypeIdentifiers

public struct ShelfItem: Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let fileSizeString: String
    public let thumbnail: NSImage?
    public let fileExtension: String
    public let isImage: Bool
    public let dateAdded: Date
    
    public init(
        id: UUID = UUID(),
        url: URL,
        thumbnail: NSImage? = nil
    ) {
        self.id = id
        self.url = url
        self.name = url.lastPathComponent
        self.fileExtension = url.pathExtension.lowercased()
        self.dateAdded = Date()
        
        let imageExtensions = ["png", "jpg", "jpeg", "heic", "gif", "webp", "tiff", "svg"]
        self.isImage = imageExtensions.contains(self.fileExtension)
        
        // Formatted file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useAll]
            formatter.countStyle = .file
            self.fileSizeString = formatter.string(fromByteCount: size)
        } else {
            self.fileSizeString = ""
        }
        
        // Thumbnail or file icon
        if let thumb = thumbnail {
            self.thumbnail = thumb
        } else {
            self.thumbnail = NSWorkspace.shared.icon(forFile: url.path)
        }
    }
    
    public static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id && lhs.url == rhs.url
    }
}
