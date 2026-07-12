import SwiftUI

/// 组合卡片：3:4 拼图封面 + 左上角场景标签 + 卡片下方组合名（PRD 3.3.2）
struct OutfitCard: View {
    let outfit: Outfit

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            AppColor.surface
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay {
                    if let cover = outfit.coverImageFileName {
                        ThumbnailImage(fileName: cover)
                    } else {
                        Image(systemName: "square.grid.2x2")
                            .font(.largeTitle)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                .overlay(alignment: .topLeading) {
                    Text(outfit.scene)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColor.onAccent)
                        .padding(.horizontal, AppSpacing.s)
                        .padding(.vertical, 3)
                        .background(AppColor.accent, in: Capsule())
                        .padding(AppSpacing.s)
                }
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

            if !outfit.name.isEmpty {
                Text(outfit.name)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, AppSpacing.xs)
            }
        }
    }
}
