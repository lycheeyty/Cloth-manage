import UIKit
import Vision
import CoreImage

/// 端侧自动抠图：使用 Vision 主体分割（iOS 17+），无网络依赖，图片不出设备
enum CutoutService {
    /// 去除背景，返回透明底图；识别不到主体或出错时返回 nil（调用方兜底用原图）
    static func removeBackground(from image: UIImage) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            performCutout(image: image)
        }.value
    }

    private static func performCutout(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation)
        )
        do {
            try handler.perform([request])
            guard let observation = request.results?.first,
                  !observation.allInstances.isEmpty else { return nil }
            let maskedBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )
            let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
            let context = CIContext()
            guard let output = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            return UIImage(cgImage: output, scale: image.scale, orientation: .up)
        } catch {
            return nil
        }
    }
}

extension CutoutService {
    /// 裁掉透明边缘，让图片边界贴合衣物实际轮廓
    /// （拖拽热区与虚线描边以此为准，避免整张 PNG 画框互相重叠）
    static func croppedToOpaqueBounds(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0,
              let context = CGContext(
                  data: nil, width: width, height: height,
                  bitsPerComponent: 8, bytesPerRow: width,
                  space: CGColorSpaceCreateDeviceGray(),
                  bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
              )
        else { return image }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return image }
        let alpha = data.bindMemory(to: UInt8.self, capacity: width * height)

        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            let row = y * width
            for x in 0..<width where alpha[row + x] > 8 {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= minX, maxY >= minY else { return image }

        let pad = 4
        let rect = CGRect(
            x: max(0, minX - pad),
            y: max(0, minY - pad),
            width: min(width - 1, maxX + pad) - max(0, minX - pad) + 1,
            height: min(height - 1, maxY + pad) - max(0, minY - pad) + 1
        )
        guard let cropped = cgImage.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: 1, orientation: .up)
    }

    /// 手动擦除：沿两点连线以圆形笔刷清除像素（点坐标为图片像素坐标）
    static func erase(in image: UIImage, from start: CGPoint, to end: CGPoint, brushRadius: CGFloat) -> UIImage {
        let size = image.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
            context.cgContext.setBlendMode(.clear)
            let distance = hypot(end.x - start.x, end.y - start.y)
            let steps = max(1, Int(distance / max(brushRadius / 2, 1)))
            for step in 0...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let point = CGPoint(
                    x: start.x + (end.x - start.x) * t,
                    y: start.y + (end.y - start.y) * t
                )
                context.cgContext.fillEllipse(in: CGRect(
                    x: point.x - brushRadius,
                    y: point.y - brushRadius,
                    width: brushRadius * 2,
                    height: brushRadius * 2
                ))
            }
        }
    }
}

extension UIImage {
    /// 超过最大边长时等比缩小，同时把方向归一化为 .up（拍摄大图先缩放再抠图，控制耗时）
    func resizedIfNeeded(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scaleFactor = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
