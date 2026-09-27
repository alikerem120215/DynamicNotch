import SwiftUI

public struct MarqueeText: View {
    public let text: String
    public let font: Font
    public let color: Color
    
    public init(text: String, font: Font = .system(size: 13, weight: .semibold), color: Color = .white) {
        self.text = text
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
