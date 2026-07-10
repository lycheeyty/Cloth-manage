import SwiftUI

/// 瀑布流卡片：统一 3:4 比例（PRD 3.2.1）
struct ClothingCard: View {
    let item: ClothingItem

    var body: some View {
        Color(.secondarySystemBackground)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                if let image = ImageStore.load(item.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "tshirt")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topLeading) {
                if !item.name.isEmpty {
                    Text(item.name)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .padding(8)
                }
            }
    }
}
