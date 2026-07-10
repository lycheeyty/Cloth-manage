import SwiftUI
import UIKit
import PhotosUI
import SwiftData
import AVFoundation

/// 添加衣服（Tab 2）：拍摄/相册上传 → 端侧自动抠图 → 逐张确认 → 发布入库
struct CaptureView: View {
    @Environment(\.modelContext) private var context
    var onPublished: () -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var drafts: [ClothingDraft] = []
    @State private var showCamera = false
    @State private var showPermissionAlert = false
    @State private var processingText: String?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let text = processingText {
                    processingView(text)
                        .toolbar(.hidden, for: .navigationBar)
                } else if drafts.isEmpty {
                    pickerPrompt
                        .toolbar(.hidden, for: .navigationBar)
                } else {
                    DraftConfirmView(
                        drafts: $drafts,
                        onPublish: publish,
                        onCancel: reset
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(
                onCapture: { image in
                    showCamera = false
                    Task { await process(images: [image]) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .alert("需要相机权限", isPresented: $showPermissionAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在系统设置中允许访问相机，用于拍摄衣物照片")
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await loadFromLibrary(newItems) }
        }
    }

    // MARK: - 子视图

    private var pickerPrompt: some View {
        VStack(spacing: AppSpacing.l) {
            EmptyStateIcon(systemName: "camera.viewfinder")
            Text("添加衣服")
                .font(AppFont.pageTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("拍下或上传衣物照片\n自动抠图后归入你的衣橱")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                openCamera()
            } label: {
                Label("拍照", systemImage: "camera")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!cameraAvailable)
            .padding(.top, AppSpacing.s)

            PhotosPicker(selection: $pickerItems, maxSelectionCount: 9, matching: .images) {
                Label("从相册选择（最多 9 张）", systemImage: "photo.on.rectangle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.accentDeep)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, 14)
                    .background(AppColor.accentSoft, in: Capsule())
            }

            if !cameraAvailable {
                Text("当前设备没有相机（模拟器），请使用相册上传")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }

    private func processingView(_ text: String) -> some View {
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
    }

    // MARK: - 流程

    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized, .notDetermined:
            showCamera = true
        default:
            showPermissionAlert = true
        }
    }

    private func loadFromLibrary(_ items: [PhotosPickerItem]) async {
        processingText = "正在载入图片…"
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        pickerItems = []
        await process(images: images)
    }

    private func process(images: [UIImage]) async {
        guard !images.isEmpty else {
            processingText = nil
            return
        }
        var newDrafts: [ClothingDraft] = []
        for (index, image) in images.enumerated() {
            processingText = images.count > 1
                ? "自动抠图中 \(index + 1)/\(images.count)…"
                : "自动抠图中…"
            let resized = image.resizedIfNeeded(maxDimension: 1600)
            let cutout = await CutoutService.removeBackground(from: resized)
            newDrafts.append(ClothingDraft(
                originalImage: resized,
                cutoutImage: cutout,
                cutoutFailed: cutout == nil
            ))
        }
        drafts = newDrafts
        processingText = nil
    }

    private func publish() {
        // 先收起键盘，避免输入框在视图销毁过程中回写数据
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
        let toSave = drafts
        processingText = "正在保存…"

        Task {
            // 图片编码与写盘放到后台线程，逐张 autoreleasepool 控制内存峰值
            let saved: [SavedDraft] = await Task.detached(priority: .userInitiated) {
                var result: [SavedDraft] = []
                for draft in toSave {
                    autoreleasepool {
                        let usesCutout = !draft.useOriginal && draft.cutoutImage != nil
                        let displayData = usesCutout
                            ? draft.displayImage.pngData()
                            : draft.displayImage.jpegData(compressionQuality: 0.85)
                        guard let data = displayData,
                              let fileName = try? ImageStore.save(data, fileExtension: usesCutout ? "png" : "jpg")
                        else { return }

                        var originalFileName: String?
                        if usesCutout, let originalData = draft.originalImage.jpegData(compressionQuality: 0.85) {
                            originalFileName = try? ImageStore.save(originalData)
                        }
                        result.append(SavedDraft(
                            name: draft.name.trimmingCharacters(in: .whitespaces),
                            category: draft.category,
                            imageFileName: fileName,
                            originalImageFileName: originalFileName
                        ))
                    }
                }
                return result
            }.value

            // SwiftData 插入回到主线程
            for record in saved {
                context.insert(ClothingItem(
                    name: record.name,
                    category: record.category,
                    imageFileName: record.imageFileName,
                    originalImageFileName: record.originalImageFileName
                ))
            }
            reset()
            onPublished()
        }
    }

    private struct SavedDraft {
        let name: String
        let category: ClothingCategory
        let imageFileName: String
        let originalImageFileName: String?
    }

    private func reset() {
        drafts = []
        pickerItems = []
        processingText = nil
    }
}

struct ClothingDraft: Identifiable {
    let id = UUID()
    let originalImage: UIImage
    var cutoutImage: UIImage?
    var cutoutFailed: Bool = false
    /// 用户选择保留原图（不用抠图结果）
    var useOriginal: Bool = false
    var name: String = ""
    var category: ClothingCategory = .other

    var displayImage: UIImage {
        if useOriginal || cutoutImage == nil {
            return originalImage
        }
        return cutoutImage!
    }
}
