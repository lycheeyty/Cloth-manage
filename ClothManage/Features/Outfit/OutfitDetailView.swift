import SwiftUI
import SwiftData

/// 组合详情页：拼图封面、场景标签、包含的单品列表（PRD 3.3.3）
struct OutfitDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var outfit: Outfit
    @State private var showDeleteConfirm = false

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.m),
        GridItem(.flexible(), spacing: AppSpacing.m),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                if let cover = outfit.coverImageFileName, let image = ImageStore.load(cover) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                }

                Text("组合名")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.textSecondary)
                TextField("组合名（选填）", text: $outfit.name)
                    .textFieldStyle(ThemedTextFieldStyle())

                Text("场景")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, AppSpacing.s)
                sceneChips

                Text("包含单品（\(outfit.items.count) 件）")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, AppSpacing.s)
                Text("长按单品可从组合中移除（不删除单品本身）")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                LazyVGrid(columns: columns, spacing: AppSpacing.m) {
                    ForEach(outfit.items) { item in
                        NavigationLink(value: item) {
                            ClothingCard(item: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                removeItem(item)
                            } label: {
                                Label("从组合中移除", systemImage: "minus.circle")
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.l)
        }
        .background(AppColor.background)
        .navigationTitle(outfit.name.isEmpty ? "组合详情" : outfit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if let cover = outfit.coverImageFileName, let coverImage = ImageStore.load(cover) {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: Image(uiImage: coverImage),
                        preview: SharePreview(
                            outfit.name.isEmpty ? "穿搭组合" : outfit.name,
                            image: Image(uiImage: coverImage)
                        )
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog(
            "删除组合不会删除其中的单品",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除组合", role: .destructive) {
                if let cover = outfit.coverImageFileName {
                    ImageStore.delete(cover)
                }
                context.delete(outfit)
                dismiss()
            }
        }
    }

    private var sceneChips: some View {
        ChipGrid(
            titles: OutfitScene.presets,
            isSelected: { outfit.scene == $0 },
            onTap: { outfit.scene = $0 }
        )
    }

    private func removeItem(_ item: ClothingItem) {
        outfit.items.removeAll { $0.persistentModelID == item.persistentModelID }
    }
}
