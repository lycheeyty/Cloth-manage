import UIKit
import SwiftUI

/// 缩略图缓存：内存 NSCache + Caches 磁盘缓存，避免瀑布流解码全尺寸大图
final class ThumbnailStore {
    static let shared = ThumbnailStore()
    private let cache = NSCache<NSString, UIImage>()
    private let maxDimension: CGFloat = 600

    private var directory: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Thumbnails", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 取缩略图：内存 → 磁盘 → 由原图生成（生成后双写缓存）
    func thumbnail(for fileName: String) -> UIImage? {
        if let cached = cache.object(forKey: fileName as NSString) {
            return cached
        }
        let thumbURL = directory.appendingPathComponent(fileName + ".thumb.png")
        if let diskImage = UIImage(contentsOfFile: thumbURL.path) {
            cache.setObject(diskImage, forKey: fileName as NSString)
            return diskImage
        }
        guard let full = ImageStore.load(fileName) else { return nil }
        let thumb = full.resizedIfNeeded(maxDimension: maxDimension)
        cache.setObject(thumb, forKey: fileName as NSString)
        // PNG 写盘，保留抠图透明底
        if let data = thumb.pngData() {
            try? data.write(to: thumbURL)
        }
        return thumb
    }

    /// 清空磁盘与内存缓存（缩略图会按需重新生成）
    func clear() {
        cache.removeAllObjects()
        try? FileManager.default.removeItem(at: directory)
    }
}

/// 异步加载缩略图的通用视图：后台解码，先显示占位色
struct ThumbnailImage: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                AppColor.surfaceSecondary
            }
        }
        .task(id: fileName) {
            guard image == nil else { return }
            let name = fileName
            image = await Task.detached(priority: .userInitiated) {
                ThumbnailStore.shared.thumbnail(for: name)
            }.value
        }
    }
}
