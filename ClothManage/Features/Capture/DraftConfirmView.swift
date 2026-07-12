import SwiftUI
import UIKit

/// 发布页：3:4 可编辑画布（拖拽/缩放/擦除）+ 分类与产品名确认
/// 多图时顶部缩略滚轮逐张确认（PRD 3.1.1）
struct DraftConfirmView: View {
    @Binding var drafts: [ClothingDraft]
    var onPublish: () -> Void
    var onCancel: () -> Void

    @State private var currentIndex = 0
    @State private var eraseMode = false

    /// 越界安全的当前草稿绑定
    private var current: Binding<ClothingDraft>? {
        guard drafts.indices.contains(currentIndex) else { return nil }
        let index = currentIndex
        return Binding(
            get: {
                drafts.indices.contains(index)
                    ? drafts[index]
                    : ClothingDraft(originalImage: UIImage(), baseCutout: nil)
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
                        DraftEditCanvas(draft: draft, eraseMode: $eraseMode)

                        canvasControls(for: draft)

                        if draft.wrappedValue.cutoutFailed {
                            Label("未能自动识别主体，可用「继续擦除」手动抠图", systemImage: "info.circle")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
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
                        ChipGrid(
                            titles: ClothingCategory.allCases.map(\.displayName),
                            isSelected: { draft.wrappedValue.category.displayName == $0 },
                            onTap: { title in
                                if let category = ClothingCategory(rawValue: title) {
                                    draft.wrappedValue.category = category
                                }
                            }
                        )

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
        .navigationTitle("发布")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消", action: onCancel)
            }
        }
        .onChange(of: currentIndex) {
            eraseMode = false
        }
    }

    // MARK: - 画布控制

    private func canvasControls(for draft: Binding<ClothingDraft>) -> some View {
        HStack(spacing: AppSpacing.s) {
            Button {
                eraseMode.toggle()
            } label: {
                Label("继续擦除", systemImage: "eraser")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(eraseMode ? AppColor.onAccent : AppColor.accentDeep)
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.vertical, AppSpacing.s)
                    .background(eraseMode ? AppColor.accent : AppColor.accentSoft, in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                eraseMode = false
                draft.wrappedValue.resetEdits()
            } label: {
                Label("恢复", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.accentDeep)
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.vertical, AppSpacing.s)
                    .background(AppColor.accentSoft, in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("底色")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Button {
                draft.wrappedValue.canvasBackground = .white
            } label: {
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(AppColor.surfaceSecondary, lineWidth: 1.5))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            ColorPicker("取色", selection: draft.canvasBackground, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 30)
        }
    }

    // MARK: - 缩略滚轮

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s) {
                ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                    Image(uiImage: draft.garmentImage)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
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

/// 3:4 编辑画布：衣物按实际轮廓大小展示（虚线描边），
/// 普通模式拖拽/双指缩放，擦除模式笔刷清除像素
private struct DraftEditCanvas: View {
    @Binding var draft: ClothingDraft
    @Binding var eraseMode: Bool

    @State private var dragStartCenter: CGPoint?
    @State private var pinchStartScale: CGFloat?
    @State private var lastErasePoint: CGPoint?

    var body: some View {
        GeometryReader { geo in
            let canvasSize = geo.size
            let garment = draft.garmentImage
            let side = canvasSize.width * 0.7 * draft.transform.scale
            let aspect = garment.size.width / max(garment.size.height, 1)
            let width = aspect >= 1 ? side : side * aspect
            let height = aspect >= 1 ? side / aspect : side
            let center = CGPoint(
                x: draft.transform.center.x * canvasSize.width,
                y: draft.transform.center.y * canvasSize.height
            )

            ZStack {
                draft.canvasBackground

                Image(uiImage: garment)
                    .resizable()
                    .frame(width: width, height: height)
                    .overlay {
                        Rectangle()
                            .stroke(
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                            .foregroundStyle(AppColor.accent.opacity(0.75))
                    }
                    .position(center)
            }
            .contentShape(Rectangle())
            // 普通模式：拖拽 + 双指缩放；擦除模式下通过 GestureMask 关闭
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartCenter == nil { dragStartCenter = draft.transform.center }
                        guard let start = dragStartCenter else { return }
                        let x = start.x + value.translation.width / canvasSize.width
                        let y = start.y + value.translation.height / canvasSize.height
                        draft.transform.center = CGPoint(
                            x: min(max(x, 0.05), 0.95),
                            y: min(max(y, 0.05), 0.95)
                        )
                    }
                    .onEnded { _ in dragStartCenter = nil },
                including: eraseMode ? .subviews : .all
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        if pinchStartScale == nil { pinchStartScale = draft.transform.scale }
                        guard let start = pinchStartScale else { return }
                        draft.transform.scale = min(max(start * value, 0.35), 2.2)
                    }
                    .onEnded { _ in pinchStartScale = nil },
                including: eraseMode ? .subviews : .all
            )
            // 擦除模式：笔刷手势
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        eraseAt(
                            value.location,
                            garmentSize: CGSize(width: width, height: height),
                            garmentCenter: center
                        )
                    }
                    .onEnded { _ in lastErasePoint = nil },
                including: eraseMode ? .all : .subviews
            )
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(AppColor.surfaceSecondary, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    /// 画布触点 → 图片像素坐标，沿轨迹擦除
    private func eraseAt(_ location: CGPoint, garmentSize: CGSize, garmentCenter: CGPoint) {
        let garment = draft.garmentImage
        guard garmentSize.width > 0, garment.size.width > 0 else { return }

        let origin = CGPoint(
            x: garmentCenter.x - garmentSize.width / 2,
            y: garmentCenter.y - garmentSize.height / 2
        )
        let pixelPerPoint = garment.size.width / garmentSize.width
        let imagePoint = CGPoint(
            x: (location.x - origin.x) * pixelPerPoint,
            y: (location.y - origin.y) * pixelPerPoint
        )
        let brushRadius = 22 * pixelPerPoint

        draft.editedCutout = CutoutService.erase(
            in: garment,
            from: lastErasePoint ?? imagePoint,
            to: imagePoint,
            brushRadius: brushRadius
        )
        lastErasePoint = imagePoint
    }
}
