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
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppColor.mint : AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.l)
                .padding(.vertical, AppSpacing.s)
                .background(isSelected ? AppColor.mintSoft : AppColor.surfaceSecondary, in: Capsule())
        }
        .buttonStyle(.plain)
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
