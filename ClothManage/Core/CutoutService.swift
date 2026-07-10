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
