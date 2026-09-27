import SwiftUI

public struct ShelfCompactView: View {
    public let itemCount: Int
    public let notchWidth: CGFloat
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left Side: Shelf Icon & Count Badge
            HStack(spacing: 4) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("\(itemCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .frame(width: 50)
            .padding(.leading, 10)
            
            Spacer()
            
            // Right Side: Arrow or quick indicator
            HStack {
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: 44)
            .padding(.trailing, 10)
        }
        .frame(height: 32)
    }
}
