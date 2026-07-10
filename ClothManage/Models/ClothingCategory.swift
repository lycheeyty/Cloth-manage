import Foundation

/// 衣物预置分类（PRD 3.1.3）
enum ClothingCategory: String, CaseIterable, Codable, Identifiable {
    case top = "上装"
    case bottom = "下装"
    case outerwear = "外套"
    case dress = "连衣裙"
    case shoes = "鞋子"
    case bag = "包袋"
    case accessory = "配饰"
    case other = "其他"

    var id: String { rawValue }
    var displayName: String { rawValue }
}
