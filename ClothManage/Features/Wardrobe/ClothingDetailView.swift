import SwiftUI
import SwiftData

struct ClothingDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ClothingItem
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = ImageStore.load(item.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    TextField("产品名（选填）", text: $item.name)
                        .textFieldStyle(.roundedBorder)

                    Picker("分类", selection: $item.category) {
                        ForEach(ClothingCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    LabeledContent("添加时间", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
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
}
