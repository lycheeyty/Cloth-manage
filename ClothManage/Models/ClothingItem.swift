import Foundation
import SwiftData

@Model
final class ClothingItem {
    var name: String
    var categoryRaw: String
    /// 展示用图（发布画布合成的 3:4 图）
    var imageFileName: String
    /// 原始照片
    var originalImageFileName: String?
    /// 贴边裁剪的透明抠图（组合画布等复用场景）
    var cutoutImageFileName: String?
    var createdAt: Date

    init(
        name: String,
        category: ClothingCategory,
        imageFileName: String,
        originalImageFileName: String? = nil,
        cutoutImageFileName: String? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.imageFileName = imageFileName
        self.originalImageFileName = originalImageFileName
        self.cutoutImageFileName = cutoutImageFileName
        self.createdAt = createdAt
    }

    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
