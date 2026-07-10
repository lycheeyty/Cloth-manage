import Foundation
import SwiftData

@Model
final class ClothingItem {
    var name: String
    var categoryRaw: String
    /// 沙盒 Documents/Images 下的文件名，展示用图（后续为抠图结果）
    var imageFileName: String
    /// 原图文件名，抠图功能接入后与展示图分开保存
    var originalImageFileName: String?
    var createdAt: Date

    init(name: String, category: ClothingCategory, imageFileName: String, originalImageFileName: String? = nil, createdAt: Date = .now) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.imageFileName = imageFileName
        self.originalImageFileName = originalImageFileName
        self.createdAt = createdAt
    }

    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
