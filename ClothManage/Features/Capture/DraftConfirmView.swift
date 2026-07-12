import SwiftUI
import UIKit

/// 发布页：多图时顶部缩略滚轮逐张确认（PRD 3.1.1 多图确认交互）
struct DraftConfirmView: View {
    @Binding var drafts: [ClothingDraft]
    var onPublish: () -> Void
    var onCancel: () -> Void

    @State private var currentIndex = 0

    /// 越界安全的当前草稿绑定：发布/取消清空数组后，
    /// 残留的输入框绑定再读写也不会崩溃
    private var current: Binding<ClothingDraft>? {
        guard drafts.indices.contains(currentIndex) else { return nil }
        let index = currentIndex
        return Binding(
            get: {
                drafts.indices.contains(index) ? drafts[index] : ClothingDraft(originalImage: UIImage())
            },
            set: { newValue in
                if drafts.indices.contains(index) {
                    drafts[index] = newValue
                }
            }
        )
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

                        HStack(spacing: AppSpacing.s) {
                            Text("分类")
                                .font(AppFont.sectionTitle)
                                .foregroundStyle(AppColor.textSecondary)
                            if draft.wrappedValue.aiRecognized {
                                Label("AI 已识别 · 可修改", systemImage: "sparkles")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppColor.mint)
                                    .padding(.horizontal, AppSpacing.s)
                                    .padding(.vertical, 3)
                                    .background(AppColor.mintSoft, in: Capsule())
                            } else {
                                Text("请选择分类")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppColor.accent)
                            }
                        }
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
        ChipGrid(
            titles: ClothingCategory.allCases.map(\.displayName),
            isSelected: { draft.wrappedValue.category.displayName == $0 },
            onTap: { title in
                if let category = ClothingCategory(rawValue: title) {
                    draft.wrappedValue.category = category
                }
            }
        )
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
