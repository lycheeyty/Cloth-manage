import SwiftUI

/// 主按钮：靛紫实色胶囊
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AppColor.onAccent)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, 14)
            .background(AppColor.accent, in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// 次按钮：浅紫实色胶囊（无描边）
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppColor.accentDeep)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, 14)
            .background(AppColor.accentSoft, in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// 分类/场景选择用小胶囊；选中态为薄荷绿点缀
/// fillWidth：在等宽网格中撑满单元格（横滑行内保持自适应宽度）
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    var fillWidth: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppColor.mint : AppColor.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: fillWidth ? .infinity : nil)
                .padding(.horizontal, AppSpacing.l)
                .padding(.vertical, AppSpacing.s)
                .background(isSelected ? AppColor.mintSoft : AppColor.surfaceSecondary, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// 分类/场景等宽胶囊网格：横向撑满屏幕（带左右边距由外层 padding 提供）
struct ChipGrid: View {
    let titles: [String]
    let isSelected: (String) -> Bool
    let onTap: (String) -> Void

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.s), count: 4)
        LazyVGrid(columns: columns, spacing: AppSpacing.s) {
            ForEach(titles, id: \.self) { title in
                CategoryChip(
                    title: title,
                    isSelected: isSelected(title),
                    fillWidth: true,
                    action: { onTap(title) }
                )
            }
        }
    }
}

/// 空状态/入口页共用布局：图标、标题、副标题、按钮槽位高度固定，
/// 保证 Tab 间切换时元素位置一致，无跳动感
struct EmptyStagePage<Buttons: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder var buttons: () -> Buttons

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            EmptyStateIcon(systemName: icon)
            Text(title)
                .font(AppFont.pageTitle)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, AppSpacing.l)
            Text(subtitle)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(height: 48, alignment: .top)
                .padding(.top, AppSpacing.s)
            buttons()
                .frame(height: 130, alignment: .top)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppSpacing.xl)
        .background(AppColor.background)
    }
}

/// 空状态图标：圆形浅底 + 主题色符号
struct EmptyStateIcon: View {
    let systemName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.accentSoft)
                .frame(width: 120, height: 120)
            Image(systemName: systemName)
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accent)
        }
    }
}

/// 设计系统样式的输入框
struct ThemedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppFont.body)
            .padding(AppSpacing.m)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.control))
    }
}
