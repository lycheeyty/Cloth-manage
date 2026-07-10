import SwiftUI
import UIKit
import SwiftData

/// 组合发布页：拼图预览 + 场景选择 + 组合名（PRD 3.3.2）
struct OutfitComposeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let items: [ClothingItem]
    var onPublished: () -> Void

    @State private var name = ""
    @State private var scene = "日常"
    @State private var customScene = ""
    @State private var isSaving = false

    private var finalScene: String {
        let trimmed = customScene.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? scene : trimmed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    previewGrid

                    Text("场景")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, AppSpacing.s)
                    sceneChips
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
    }

    private var previewGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: AppSpacing.s),
            GridItem(.flexible(), spacing: AppSpacing.s),
        ]
        return LazyVGrid(columns: columns, spacing: AppSpacing.s) {
            ForEach(items) { item in
                AppColor.surface
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay {
                        if let image = ImageStore.load(item.imageFileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .padding(AppSpacing.s)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))
            }
        }
    }

    private var sceneChips: some View {
        let chipColumns = [GridItem(.adaptive(minimum: 72), spacing: AppSpacing.s)]
        return LazyVGrid(columns: chipColumns, spacing: AppSpacing.s) {
            ForEach(OutfitScene.presets, id: \.self) { preset in
                CategoryChip(
                    title: preset,
                    isSelected: customScene.trimmingCharacters(in: .whitespaces).isEmpty && scene == preset,
                    action: {
                        scene = preset
                        customScene = ""
                    }
                )
            }
        }
    }

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

    private func publish() {
        isSaving = true
        let images = items.compactMap { ImageStore.load($0.imageFileName) }
        let outfitName = name.trimmingCharacters(in: .whitespaces)
        let sceneName = finalScene
        let selectedItems = items

        Task {
            // 拼图渲染与写盘放后台线程
            let coverFileName: String? = await Task.detached(priority: .userInitiated) {
                let cover = CollageRenderer.render(images: images)
                guard let data = cover.jpegData(compressionQuality: 0.9) else { return nil }
                return try? ImageStore.save(data)
            }.value

            context.insert(Outfit(
                name: outfitName,
                scene: sceneName,
                items: selectedItems,
                coverImageFileName: coverFileName
            ))
            isSaving = false
            dismiss()
            onPublished()
        }
    }
}
