import SwiftUI
import PhotosUI
import SwiftData

/// 添加衣服（Tab 2）。第一版先支持相册多选上传 → 逐张填写信息 → 发布入库；
/// 相机拍摄与端侧抠图在下一个迭代接入。
struct CaptureView: View {
    @Environment(\.modelContext) private var context
    var onPublished: () -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var drafts: [ClothingDraft] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("正在载入图片…")
                } else if drafts.isEmpty {
                    pickerPrompt
                } else {
                    DraftConfirmView(
                        drafts: $drafts,
                        onPublish: publish,
                        onCancel: reset
                    )
                }
            }
            .navigationTitle("添加衣服")
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await loadDrafts(from: newItems) }
        }
    }

    private var pickerPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("拍下或上传衣物照片")
                .font(.headline)
            PhotosPicker(selection: $pickerItems, maxSelectionCount: 9, matching: .images) {
                Label("从相册选择（最多 9 张）", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.borderedProminent)
            Text("相机拍摄与自动抠图即将上线")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    private func loadDrafts(from items: [PhotosPickerItem]) async {
        isLoading = true
        var loaded: [ClothingDraft] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(ClothingDraft(imageData: data, image: image))
            }
        }
        drafts = loaded
        pickerItems = []
        isLoading = false
    }

    private func publish() {
        for draft in drafts {
            guard let fileName = try? ImageStore.save(draft.imageData) else { continue }
            let item = ClothingItem(
                name: draft.name.trimmingCharacters(in: .whitespaces),
                category: draft.category,
                imageFileName: fileName
            )
            context.insert(item)
        }
        reset()
        onPublished()
    }

    private func reset() {
        drafts = []
        pickerItems = []
    }
}

struct ClothingDraft: Identifiable {
    let id = UUID()
    let imageData: Data
    let image: UIImage
    var name: String = ""
    var category: ClothingCategory = .other
}
