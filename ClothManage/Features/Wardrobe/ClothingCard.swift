import SwiftUI

/// 瀑布流卡片：统一 3:4 比例（PRD 3.2.1）
struct ClothingCard: View {
    let item: ClothingItem

    var body: some View {
        AppColor.surface
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                if let image = ImageStore.load(item.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "tshirt")
                        .font(.largeTitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .overlay(alignment: .topLeading) {
                if !item.name.isEmpty {
                    Text(item.name)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, AppSpacing.s)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColor.surface.opacity(0.92), in: Capsule())
                        .padding(AppSpacing.s)
                }
            }
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}
