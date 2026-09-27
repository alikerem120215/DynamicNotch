import SwiftUI
import AppKit

@MainActor
public struct NotchShelfView: View {
    @ObservedObject public var shelfManager: DropShelfManager
    public var onClose: () -> Void
    
    public init(
        shelfManager: DropShelfManager,
        onClose: @escaping () -> Void = {}
    ) {
        self.shelfManager = shelfManager
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Çentik Rafı (\(shelfManager.itemCount))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Clear All Button
                if shelfManager.hasItems {
                    Button(action: {
                        shelfManager.clearAll()
                        onClose()
                    }) {
                        Text("Tümünü Temizle")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Items List / Grid
            if shelfManager.items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Dosya, resim veya video sürükleyin")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shelfManager.items) { item in
                            ShelfCardView(item: item, shelfManager: shelfManager)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(width: 480)
    }
}

// Individual file card on the shelf
public struct ShelfCardView: View {
    public let item: ShelfItem
    @ObservedObject public var shelfManager: DropShelfManager
    
    public var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail / Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 80, height: 75)
                    
                    if let thumb = item.thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 68, height: 65)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Image(systemName: item.isImage ? "photo" : "doc.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Remove button
                Button(action: {
                    shelfManager.removeItem(id: item.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .background(Circle().fill(Color.black.opacity(0.7)))
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: 4, y: -4)
            }
            
            // File name
            Text(item.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .frame(width: 80)
            
            // File size
            if !item.fileSizeString.isEmpty {
                Text(item.fileSizeString)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        // Drag-out support: Click and drag anywhere out of the shelf!
        .onDrag {
            NSItemProvider(contentsOf: item.url) ?? NSItemProvider()
        }
        .contextMenu {
            Button("Aç") {
                shelfManager.openItem(item)
            }
            Button("Finder'da Göster") {
                shelfManager.revealInFinder(item)
            }
            Divider()
            Button("Raftan Kaldır", role: .destructive) {
                shelfManager.removeItem(id: item.id)
            }
        }
    }
}

// Active drop target banner view
public struct DropTargetBannerView: View {
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.cyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Dosyayı Çentiğe Bırakın")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Çentik rafında saklanacak ve istenildiğinde geri alınabilir")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan, Color.blue.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
        )
        .frame(maxWidth: .infinity)
    }
}
