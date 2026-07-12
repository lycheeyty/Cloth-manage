import SwiftUI
import UIKit
import SwiftData

/// 画布上单件衣物的位置与缩放（中心点为 0–1 归一化坐标）
struct CanvasTransform {
    var center: CGPoint
    var scale: CGFloat
}

/// 组合发布页：3:4 可编辑画布（拖拽 / 双指缩放）+ 场景选择 + 组合名
struct OutfitComposeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let items: [ClothingItem]
    var onPublished: () -> Void

    @State private var name = ""
    @State private var scene = "日常"
    @State private var customScene = ""
    @State private var isSaving = false
    @State private var transforms: [CanvasTransform] = []
    @State private var canvasImages: [UIImage] = []

    private var finalScene: String {
        let trimmed = customScene.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? scene : trimmed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    canvas
                    Text("拖动调整位置，双指缩放大小；发布后可在详情页分享/保存这张图")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    Text("场景")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, AppSpacing.s)
                    ChipGrid(
                        titles: OutfitScene.presets,
                        isSelected: { customScene.trimmingCharacters(in: .whitespaces).isEmpty && scene == $0 },
                        onTap: { preset in
                            scene = preset
                            customScene = ""
                        }
                    )
                    TextField("自定义场景（选填，填写后优先使用）", text: $customScene)
                        .textFieldStyle(ThemedTextFieldStyle())

                    Text("组合名（选填）")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, AppSpacing.s)
                    TextField("如：\(finalScene)穿搭", text: $name)
                        .textFieldStyle(ThemedTextFieldStyle())
                }
                .padding(AppSpacing.l)
            }
            .background(AppColor.background)
            .navigationTitle("创建组合")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                publishBar
            }
        }
        .interactiveDismissDisabled(isSaving)
        .onAppear(perform: prepareCanvas)
    }

    // MARK: - 画布

    private var canvas: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(canvasImages.indices, id: \.self) { index in
                    if transforms.indices.contains(index) {
                        CanvasItemView(
                            image: canvasImages[index],
                            transform: $transforms[index],
                            canvasSize: geo.size
                        )
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func prepareCanvas() {
        guard transforms.isEmpty else { return }
        // 优先用透明抠图并裁到实际轮廓：拖拽热区/描边贴合衣物本身
        canvasImages = items.map { item in
            let fileName = item.cutoutImageFileName ?? item.imageFileName
            let image = ThumbnailStore.shared.thumbnail(for: fileName)
                ?? ImageStore.load(fileName)
                ?? UIImage()
            return CutoutService.croppedToOpaqueBounds(image)
        }
        transforms = Self.defaultTransforms(count: items.count)
    }

    /// 初始网格排布：双列，奇数张末张居中
    static func defaultTransforms(count: Int) -> [CanvasTransform] {
        let rows = max(1, Int(ceil(Double(count) / 2)))
        return (0..<count).map { index in
            let col = index % 2
            let row = index / 2
            var x: Double = col == 0 ? 0.28 : 0.72
            if count == 1 || (count % 2 == 1 && index == count - 1) {
                x = 0.5
            }
            let y = (Double(row) + 0.5) / Double(rows)
            return CanvasTransform(
                center: CGPoint(x: x, y: y),
                scale: rows > 2 ? 0.75 : 1.0
            )
        }
    }

    // MARK: - 发布

    private var publishBar: some View {
        HStack {
            Text("\(items.count) 件单品")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Button(isSaving ? "正在生成…" : "发布组合") {
                publish()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSaving)
        }
        .padding(AppSpacing.l)
        .background(.bar)
    }

    @MainActor
    private func publish() {
        isSaving = true
        // 导出用全尺寸抠图（同样裁到实际轮廓），按画布归一化位置渲染
        let fullImages = items.map { item in
            let fileName = item.cutoutImageFileName ?? item.imageFileName
            let image = ImageStore.load(fileName) ?? UIImage()
            return CutoutService.croppedToOpaqueBounds(image)
        }
        let exportSize = CGSize(width: 900, height: 1200)
        let renderer = ImageRenderer(content: CollageExportView(
            images: fullImages,
            transforms: transforms,
            size: exportSize
        ))
        renderer.scale = 1

        var coverFileName: String?
        if let cover = renderer.uiImage, let data = cover.pngData() {
            coverFileName = try? ImageStore.save(data, fileExtension: "png")
        }

        context.insert(Outfit(
            name: name.trimmingCharacters(in: .whitespaces),
            scene: finalScene,
            items: items,
            coverImageFileName: coverFileName
        ))
        isSaving = false
        dismiss()
        onPublished()
    }
}

/// 画布上的单件衣物：拖拽移动 + 双指缩放
private struct CanvasItemView: View {
    let image: UIImage
    @Binding var transform: CanvasTransform
    let canvasSize: CGSize

    @State private var dragStartCenter: CGPoint?
    @State private var pinchStartScale: CGFloat?

    var body: some View {
        // 尺寸按衣物实际轮廓的宽高比计算，描边与热区贴合衣物本身
        let side = canvasSize.width * 0.48 * transform.scale
        let aspect = image.size.width / max(image.size.height, 1)
        let width = aspect >= 1 ? side : side * aspect
        let height = aspect >= 1 ? side / aspect : side
        Image(uiImage: image)
            .resizable()
            .frame(width: width, height: height)
            .overlay {
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    .foregroundStyle(AppColor.accent.opacity(0.55))
            }
            .position(
                x: transform.center.x * canvasSize.width,
                y: transform.center.y * canvasSize.height
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartCenter == nil { dragStartCenter = transform.center }
                        guard let start = dragStartCenter, canvasSize.width > 0 else { return }
                        let x = start.x + value.translation.width / canvasSize.width
                        let y = start.y + value.translation.height / canvasSize.height
                        transform.center = CGPoint(
                            x: min(max(x, 0.05), 0.95),
                            y: min(max(y, 0.05), 0.95)
                        )
                    }
                    .onEnded { _ in dragStartCenter = nil }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        if pinchStartScale == nil { pinchStartScale = transform.scale }
                        guard let start = pinchStartScale else { return }
                        transform.scale = min(max(start * value, 0.35), 2.5)
                    }
                    .onEnded { _ in pinchStartScale = nil }
            )
    }
}

/// 导出视图：与画布相同的归一化布局，透明底，用 ImageRenderer 生成封面图
private struct CollageExportView: View {
    let images: [UIImage]
    let transforms: [CanvasTransform]
    let size: CGSize

    var body: some View {
        ZStack {
            ForEach(images.indices, id: \.self) { index in
                if transforms.indices.contains(index) {
                    let transform = transforms[index]
                    let side = size.width * 0.48 * transform.scale
                    let aspect = images[index].size.width / max(images[index].size.height, 1)
                    let width = aspect >= 1 ? side : side * aspect
                    let height = aspect >= 1 ? side / aspect : side
                    Image(uiImage: images[index])
                        .resizable()
                        .frame(width: width, height: height)
                        .position(
                            x: transform.center.x * size.width,
                            y: transform.center.y * size.height
                        )
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
