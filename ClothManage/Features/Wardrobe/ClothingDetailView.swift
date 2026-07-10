import SwiftUI
import SwiftData

struct ClothingDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ClothingItem
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                if let image = ImageStore.load(item.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                        .padding(.horizontal, AppSpacing.l)
                }

                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    Text("产品名")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                    TextField("产品名（选填）", text: $item.name)
                        .textFieldStyle(ThemedTextFieldStyle())

                    Text("分类")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, AppSpacing.s)
                    categoryChips

                    LabeledContent("添加时间", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, AppSpacing.s)
                }
                .padding(.horizontal, AppSpacing.l)
            }
            .padding(.vertical, AppSpacing.l)
        }
        .background(AppColor.background)
        .navigationTitle(item.name.isEmpty ? "衣物详情" : item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("确定删除这件衣物吗？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                ImageStore.delete(item.imageFileName)
                if let original = item.originalImageFileName {
                    ImageStore.delete(original)
                }
                context.delete(item)
                dismiss()
            }
        }
    }

    private var categoryChips: some View {
        let columns = [GridItem(.adaptive(minimum: 76), spacing: AppSpacing.s)]
        return LazyVGrid(columns: columns, spacing: AppSpacing.s) {
            ForEach(ClothingCategory.allCases) { category in
                CategoryChip(
                    title: category.displayName,
                    isSelected: item.category == category,
                    action: { item.category = category }
                )
            }
        }
    }
}
