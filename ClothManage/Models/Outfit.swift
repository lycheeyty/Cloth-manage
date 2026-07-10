import Foundation
import SwiftData

@Model
final class Outfit {
    var name: String
    /// 场景标签：上班、度假、约会、运动、日常、聚会、其他或自定义
    var scene: String
    var createdAt: Date
    /// 拼图封面文件名（沙盒 Documents/Images 下）
    var coverImageFileName: String?
    var items: [ClothingItem]

    init(
        name: String,
        scene: String,
        items: [ClothingItem],
        coverImageFileName: String? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.scene = scene
        self.items = items
        self.coverImageFileName = coverImageFileName
        self.createdAt = createdAt
    }
}

/// 预置场景标签（PRD 3.3.2）
enum OutfitScene {
    static let presets = ["上班", "度假", "约会", "运动", "日常", "聚会", "其他"]
}
