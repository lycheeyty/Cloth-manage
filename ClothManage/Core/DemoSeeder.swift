import UIKit
import SwiftData

/// 截图/演示用示例数据。仅通过启动参数触发（--wipe-data / --seed-demo），
/// 正常使用永远不会执行
enum DemoSeeder {
    static func wipe(container: ModelContainer) {
        let context = ModelContext(container)
        try? context.delete(model: Outfit.self)
        try? context.delete(model: ClothingItem.self)
        try? context.save()
        let files = (try? FileManager.default.contentsOfDirectory(atPath: ImageStore.directory.path)) ?? []
        for file in files {
            ImageStore.delete(file)
        }
        ThumbnailStore.shared.clear()
        UserDefaults.standard.set("全部", forKey: "wardrobeFilter")
    }

    static func seed(container: ModelContainer) {
        let context = ModelContext(container)
        let specs: [(String, ClothingCategory, UIColor)] = [
            ("白色针织开衫", .top, UIColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1)),
            ("直筒牛仔裤", .bottom, UIColor(red: 0.42, green: 0.51, blue: 0.62, alpha: 1)),
            ("驼色大衣", .outerwear, UIColor(red: 0.76, green: 0.60, blue: 0.42, alpha: 1)),
            ("碎花连衣裙", .dress, UIColor(red: 0.85, green: 0.62, blue: 0.65, alpha: 1)),
            ("白色帆布鞋", .shoes, UIColor(red: 0.88, green: 0.88, blue: 0.86, alpha: 1)),
            ("黑色单肩包", .bag, UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1)),
            ("珍珠项链", .accessory, UIColor(red: 0.90, green: 0.87, blue: 0.80, alpha: 1)),
            ("灰色卫衣", .top, UIColor(red: 0.58, green: 0.58, blue: 0.60, alpha: 1)),
        ]

        var itemsByName: [String: ClothingItem] = [:]
        for (offset, spec) in specs.enumerated() {
            let image = drawGarment(category: spec.1, color: spec.2)
            guard let data = image.pngData(),
                  let fileName = try? ImageStore.save(data, fileExtension: "png") else { continue }
            let item = ClothingItem(
                name: spec.0,
                category: spec.1,
                imageFileName: fileName,
                createdAt: Date().addingTimeInterval(TimeInterval(-offset) * 3600)
            )
            context.insert(item)
            itemsByName[spec.0] = item
        }

        // 一套演示组合
        let outfitItems = ["白色针织开衫", "直筒牛仔裤", "白色帆布鞋"].compactMap { itemsByName[$0] }
        if outfitItems.count >= 2 {
            let images = outfitItems.compactMap { ImageStore.load($0.imageFileName) }
            let cover = CollageRenderer.render(images: images)
            var coverFile: String?
            if let data = cover.pngData() {
                coverFile = try? ImageStore.save(data, fileExtension: "png")
            }
            context.insert(Outfit(
                name: "初秋通勤",
                scene: "上班",
                items: outfitItems,
                coverImageFileName: coverFile,
                createdAt: Date().addingTimeInterval(-1800)
            ))
        }
        try? context.save()
    }

    /// 画一件简易衣物示意图（透明底），截图演示用
    static func drawGarment(category: ClothingCategory, color: UIColor) -> UIImage {
        let size = CGSize(width: 600, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(x: 60, y: 80, width: 480, height: 640)
            color.setFill()
            garmentPath(category: category, in: rect).fill()
        }
    }

    private static func garmentPath(category: ClothingCategory, in rect: CGRect) -> UIBezierPath {
        switch category {
        case .top, .outerwear:
            let p = UIBezierPath()
            p.move(to: pt(rect, 0.10, 0.10))
            p.addLine(to: pt(rect, 0.32, 0.00))
            p.addQuadCurve(to: pt(rect, 0.68, 0.00), controlPoint: pt(rect, 0.50, 0.12))
            p.addLine(to: pt(rect, 0.90, 0.10))
            p.addLine(to: pt(rect, 1.00, 0.32))
            p.addLine(to: pt(rect, 0.80, 0.42))
            p.addLine(to: pt(rect, 0.80, 1.00))
            p.addLine(to: pt(rect, 0.20, 1.00))
            p.addLine(to: pt(rect, 0.20, 0.42))
            p.addLine(to: pt(rect, 0.00, 0.32))
            p.close()
            return p
        case .bottom:
            let p = UIBezierPath()
            p.move(to: pt(rect, 0.20, 0.00))
            p.addLine(to: pt(rect, 0.80, 0.00))
            p.addLine(to: pt(rect, 0.88, 1.00))
            p.addLine(to: pt(rect, 0.60, 1.00))
            p.addLine(to: pt(rect, 0.50, 0.35))
            p.addLine(to: pt(rect, 0.40, 1.00))
            p.addLine(to: pt(rect, 0.12, 1.00))
            p.close()
            return p
        case .dress:
            let p = UIBezierPath()
            p.move(to: pt(rect, 0.30, 0.00))
            p.addLine(to: pt(rect, 0.44, 0.00))
            p.addQuadCurve(to: pt(rect, 0.56, 0.00), controlPoint: pt(rect, 0.50, 0.08))
            p.addLine(to: pt(rect, 0.70, 0.00))
            p.addLine(to: pt(rect, 0.62, 0.30))
            p.addLine(to: pt(rect, 0.85, 0.95))
            p.addQuadCurve(to: pt(rect, 0.15, 0.95), controlPoint: pt(rect, 0.50, 1.05))
            p.addLine(to: pt(rect, 0.38, 0.30))
            p.close()
            return p
        case .shoes:
            let p = UIBezierPath()
            p.move(to: pt(rect, 0.10, 0.55))
            p.addQuadCurve(to: pt(rect, 0.45, 0.62), controlPoint: pt(rect, 0.28, 0.52))
            p.addQuadCurve(to: pt(rect, 0.92, 0.85), controlPoint: pt(rect, 0.75, 0.68))
            p.addLine(to: pt(rect, 0.92, 0.95))
            p.addLine(to: pt(rect, 0.08, 0.95))
            p.close()
            return p
        case .bag:
            return UIBezierPath(
                roundedRect: CGRect(
                    x: rect.minX + rect.width * 0.15,
                    y: rect.minY + rect.height * 0.30,
                    width: rect.width * 0.70,
                    height: rect.height * 0.55
                ),
                cornerRadius: 40
            )
        case .accessory:
            return UIBezierPath(ovalIn: CGRect(
                x: rect.minX + rect.width * 0.25,
                y: rect.minY + rect.height * 0.30,
                width: rect.width * 0.50,
                height: rect.width * 0.50
            ))
        case .other:
            return UIBezierPath(
                roundedRect: rect.insetBy(dx: rect.width * 0.2, dy: rect.height * 0.2),
                cornerRadius: 30
            )
        }
    }

    private static func pt(_ rect: CGRect, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }
}
