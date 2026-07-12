import SwiftUI

/// 瀑布流卡片：统一 3:4 图片 + 卡片下方产品名
struct ClothingCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            AppColor.surface
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay {
                    ThumbnailImage(fileName: item.imageFileName)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

            if !item.name.isEmpty {
                Text(item.name)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, AppSpacing.xs)
            }
        }
    }
}
