import SwiftUI
import UIKit
import SwiftData

/// 发布流程（全屏）：自动抠图 → 发布页（画布编辑 + 信息确认）→ 入库
struct CaptureFlowView: View {
    @Environment(\.modelContext) private var context
    let images: [UIImage]
    /// published = true 表示成功发布，false 表示取消
    var onFinish: (_ published: Bool) -> Void

    @State private var drafts: [ClothingDraft] = []
    @State private var processingText: String? = "自动抠图中…"
    @AppStorage("imageQuality") private var imageQuality = "原图"

    var body: some View {
        NavigationStack {
            Group {
                if let text = processingText {
                    VStack(spacing: AppSpacing.l) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(AppColor.accent)
                        Text(text)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColor.background)
                } else {
                    DraftConfirmView(
                        drafts: $drafts,
                        onPublish: publish,
                        onCancel: { onFinish(false) }
                    )
                }
            }
        }
        .interactiveDismissDisabled()
        .task { await process() }
    }

    private func process() async {
        guard drafts.isEmpty else { return }
        var newDrafts: [ClothingDraft] = []
        for (index, image) in images.enumerated() {
            processingText = images.count > 1
                ? "自动抠图中 \(index + 1)/\(images.count)…"
                : "自动抠图中…"
            let resized = image.resizedIfNeeded(maxDimension: 1600)
            var cutout = await CutoutService.removeBackground(from: resized)
            if let raw = cutout {
                cutout = CutoutService.croppedToOpaqueBounds(raw)
            }
            var draft = ClothingDraft(
                originalImage: resized,
                baseCutout: cutout,
                cutoutFailed: cutout == nil
            )
            // AI 分类预填（首版 Mock）
            if let result = await MockClassificationService.shared.classify(cutout ?? resized) {
                draft.category = result.category
                if let suggested = result.suggestedName {
                    draft.name = suggested
                }
                draft.aiRecognized = true
            }
            newDrafts.append(draft)
        }
        drafts = newDrafts
        processingText = nil
    }

    @MainActor
    private func publish() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
        processingText = "正在保存…"
        let jpegQuality: CGFloat = imageQuality == "压缩" ? 0.6 : 0.85
        let toSave = drafts

        Task { @MainActor in
            for draft in toSave {
                // 展示图：按画布布局（含底色）合成 3:4 图
                let renderer = ImageRenderer(content: DraftExportView(
                    draft: draft,
                    size: CGSize(width: 900, height: 1200)
                ))
                renderer.scale = 1
                guard let display = renderer.uiImage,
                      let displayData = display.jpegData(compressionQuality: jpegQuality),
                      let displayFile = try? ImageStore.save(displayData)
                else { continue }

                // 透明抠图（组合画布复用）与原始照片分别存档
                var cutoutFile: String?
                if !draft.cutoutFailed, let cutoutData = draft.garmentImage.pngData() {
                    cutoutFile = try? ImageStore.save(cutoutData, fileExtension: "png")
                }
                var originalFile: String?
                if let originalData = draft.originalImage.jpegData(compressionQuality: jpegQuality) {
                    originalFile = try? ImageStore.save(originalData)
                }

                context.insert(ClothingItem(
                    name: draft.name.trimmingCharacters(in: .whitespaces),
                    category: draft.category,
                    imageFileName: displayFile,
                    originalImageFileName: originalFile,
                    cutoutImageFileName: cutoutFile
                ))
            }
            onFinish(true)
        }
    }
}

/// 发布页草稿：画布编辑状态 + 信息
struct ClothingDraft: Identifiable {
    let id = UUID()
    /// 原始照片
    let originalImage: UIImage
    /// 初始抠图（已贴边裁剪），「恢复」按钮回到这里
    let baseCutout: UIImage?
    /// 手动擦除后的当前图
    var editedCutout: UIImage?
    var cutoutFailed: Bool = false
    /// 画布上的位置与缩放
    var transform = CanvasTransform(center: CGPoint(x: 0.5, y: 0.5), scale: 1.0)
    /// 画布底色（白色或自选取色）
    var canvasBackground: Color = .white
    var aiRecognized: Bool = false
    var name: String = ""
    var category: ClothingCategory = .other

    /// 画布上展示的衣物图
    var garmentImage: UIImage {
        editedCutout ?? baseCutout ?? originalImage
    }

    mutating func resetEdits() {
        editedCutout = nil
        transform = CanvasTransform(center: CGPoint(x: 0.5, y: 0.5), scale: 1.0)
    }
}

/// 导出视图：与发布页画布相同的归一化布局，底色烘焙进图片
struct DraftExportView: View {
    let draft: ClothingDraft
    let size: CGSize

    var body: some View {
        let garment = draft.garmentImage
        let side = size.width * 0.7 * draft.transform.scale
        let aspect = garment.size.width / max(garment.size.height, 1)
        let width = aspect >= 1 ? side : side * aspect
        let height = aspect >= 1 ? side / aspect : side

        ZStack {
            draft.canvasBackground
            Image(uiImage: garment)
                .resizable()
                .frame(width: width, height: height)
                .position(
                    x: draft.transform.center.x * size.width,
                    y: draft.transform.center.y * size.height
                )
        }
        .frame(width: size.width, height: size.height)
    }
}
