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
                    VStack(alignment: .leading, spacing: AppSpacing.m) {
                        Image(uiImage: draft.wrappedValue.displayImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 320)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                        if draft.wrappedValue.cutoutFailed {
                            Label("未能识别主体，已使用原图", systemImage: "info.circle")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        } else {
                            Toggle("保留原图（不使用抠图结果）", isOn: draft.useOriginal)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .tint(AppColor.accent)
                        }

                        Text("分类")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.textSecondary)
                            .padding(.top, AppSpacing.s)
                        categoryGrid(for: draft)

                        Text("产品名（选填）")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.textSecondary)
                            .padding(.top, AppSpacing.s)
                        TextField("如：白色针织开衫", text: draft.name)
                            .textFieldStyle(ThemedTextFieldStyle())
                    }
                    .padding(AppSpacing.l)
                }
            }

            bottomBar
        }
        .background(AppColor.background)
        .navigationTitle("确认信息")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消", action: onCancel)
            }
        }
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s) {
                ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                    Image(uiImage: draft.displayImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.control)
                                .stroke(index == currentIndex ? AppColor.accent : .clear, lineWidth: 2)
                        }
                        .onTapGesture { currentIndex = index }
                }
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.vertical, AppSpacing.s)
        }
    }

    private func categoryGrid(for draft: Binding<ClothingDraft>) -> some View {
        let columns = [GridItem(.adaptive(minimum: 76), spacing: AppSpacing.s)]
        return LazyVGrid(columns: columns, spacing: AppSpacing.s) {
            ForEach(ClothingCategory.allCases) { category in
                CategoryChip(
                    title: category.displayName,
                    isSelected: draft.wrappedValue.category == category,
                    action: { draft.wrappedValue.category = category }
                )
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            if drafts.count > 1 {
                Text("\(currentIndex + 1) / \(drafts.count)")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            if drafts.count > 1 && currentIndex < drafts.count - 1 {
                Button("下一张") { currentIndex += 1 }
                    .buttonStyle(SecondaryButtonStyle())
            }
            Button("发布 (\(drafts.count) 件)", action: onPublish)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(AppSpacing.l)
        .background(AppColor.surface)
    }
}
