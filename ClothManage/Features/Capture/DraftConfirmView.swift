import SwiftUI

/// 发布页：多图时顶部缩略滚轮逐张确认（PRD 3.1.1 多图确认交互）
struct DraftConfirmView: View {
    @Binding var drafts: [ClothingDraft]
    var onPublish: () -> Void
    var onCancel: () -> Void

    @State private var currentIndex = 0

    private var current: Binding<ClothingDraft>? {
        guard drafts.indices.contains(currentIndex) else { return nil }
        return $drafts[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            if drafts.count > 1 {
                thumbnailStrip
            }

            if let draft = current {
                ScrollView {
                    VStack(spacing: 16) {
                        Image(uiImage: draft.wrappedValue.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("分类")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            categoryGrid(for: draft)

                            Text("产品名（选填）")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("如：白色针织开衫", text: draft.name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                }
            }

            bottomBar
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消", action: onCancel)
            }
        }
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                    Image(uiImage: draft.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(index == currentIndex ? Color.accentColor : .clear, lineWidth: 2)
                        }
                        .onTapGesture { currentIndex = index }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func categoryGrid(for draft: Binding<ClothingDraft>) -> some View {
        let columns = [GridItem(.adaptive(minimum: 72), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ClothingCategory.allCases) { category in
                Button {
                    draft.wrappedValue.category = category
                } label: {
                    Text(category.displayName)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            draft.wrappedValue.category == category
                                ? Color.accentColor.opacity(0.2)
                                : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            if drafts.count > 1 {
                Text("\(currentIndex + 1) / \(drafts.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if drafts.count > 1 && currentIndex < drafts.count - 1 {
                Button("下一张") { currentIndex += 1 }
                    .buttonStyle(.bordered)
            }
            Button("发布 (\(drafts.count) 件)", action: onPublish)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.bar)
    }
}
