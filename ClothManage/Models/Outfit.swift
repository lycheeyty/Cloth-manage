import Foundation
import SwiftData

@Model
final class Outfit {
    var name: String
    /// 场景标签：上班、度假、约会、运动、日常、聚会、其他或自定义
    var scene: String
    var createdAt: Date
    var items: [ClothingItem]

    init(name: String, scene: String, items: [ClothingItem], createdAt: Date = .now) {
        self.name = name
        self.scene = scene
        self.items = items
        self.createdAt = createdAt
    }
}
