import UIKit

struct ClassificationResult {
    let category: ClothingCategory
    let confidence: Double
    let suggestedName: String?
}

/// 分类识别服务协议。首版由 Mock 实现；v1.1 接入云端多模态识别时
/// 替换实现即可，UI 层不感知来源（PRD 3.1.3）
protocol ClassificationService {
    func classify(_ image: UIImage) async -> ClassificationResult?
}

/// Mock 实现：不做真实识别，随机给出预填结果；
/// 返回 nil 表示「低置信度」，UI 不预填并提示用户手选
struct MockClassificationService: ClassificationService {
    static let shared = MockClassificationService()

    private static let nameSuggestions: [ClothingCategory: [String]] = [
        .top: ["白色针织开衫", "条纹长袖T恤", "奶油色卫衣", "基础款圆领T恤"],
        .bottom: ["直筒牛仔裤", "高腰阔腿裤", "百褶半身裙", "黑色西装裤"],
        .outerwear: ["驼色大衣", "黑色皮夹克", "灰色西装外套", "牛仔外套"],
        .dress: ["碎花连衣裙", "针织连衣裙", "吊带长裙", "衬衫式连衣裙"],
        .shoes: ["白色帆布鞋", "黑色乐福鞋", "棕色短靴", "运动跑鞋"],
        .bag: ["黑色单肩包", "帆布托特包", "迷你斜挎包", "通勤电脑包"],
        .accessory: ["珍珠项链", "真丝方巾", "金属细腰带", "针织贝雷帽"],
        .other: [],
    ]

    func classify(_ image: UIImage) async -> ClassificationResult? {
        // 模拟识别耗时，让加载态可感知
        try? await Task.sleep(nanoseconds: 300_000_000)
        // 约 15% 概率模拟低置信度：不预填
        guard Double.random(in: 0...1) > 0.15 else { return nil }
        let category = ClothingCategory.allCases.filter { $0 != .other }.randomElement() ?? .top
        let name = Self.nameSuggestions[category]?.randomElement()
        return ClassificationResult(category: category, confidence: 0.9, suggestedName: name)
    }
}
