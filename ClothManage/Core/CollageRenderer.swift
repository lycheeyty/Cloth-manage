import UIKit

/// 组合拼图封面渲染：固定网格模板（PRD 3.3.2，v1 方案）
enum CollageRenderer {
    /// 渲染 3:4 拼图封面（双列网格，奇数张时最后一张居中）
    static func render(images: [UIImage], size: CGSize = CGSize(width: 900, height: 1200)) -> UIImage {
        let cols = 2
        let rows = max(1, Int(ceil(Double(images.count) / Double(cols))))
        let cellWidth = size.width / CGFloat(cols)
        let cellHeight = size.height / CGFloat(rows)
        let inset: CGFloat = 24

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 固定浅色底，保证封面在深浅色模式下观感一致
            UIColor(red: 0.957, green: 0.953, blue: 0.984, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for (index, image) in images.enumerated() {
                let col = index % cols
                let row = index / cols
                var cell = CGRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                ).insetBy(dx: inset, dy: inset)

                // 奇数张时最后一张水平居中
                if images.count % cols == 1 && index == images.count - 1 {
                    cell.origin.x = (size.width - cell.width) / 2
                }

                image.draw(in: aspectFitRect(imageSize: image.size, in: cell))
            }
        }
    }

    private static func aspectFitRect(imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: rect.midX - fittedSize.width / 2,
            y: rect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}
