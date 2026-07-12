import SwiftUI
import UIKit

/// 设计系统 · 颜色令牌（自动适配深色模式）
/// 方案 F「靛紫主导」：长春花靛紫为主色，薄荷绿点缀，海军蓝文字，纯白底
/// 深色模式为深靛蓝底（非灰黑），与主色系统一
enum AppColor {
    /// 页面底色（深色模式为低饱和灰，仅带一丝冷调）
    static let background = dynamic(light: 0xFFFFFF, dark: 0x141519)
    /// 卡片、输入框等表面
    static let surface = dynamic(light: 0xF4F3FB, dark: 0x1E1F26)
    /// 次级表面：占位、未选中态
    static let surfaceSecondary = dynamic(light: 0xE7E6F7, dark: 0x2A2B33)
    /// 主文字：海军蓝
    static let textPrimary = dynamic(light: 0x16174B, dark: 0xECEDF2)
    /// 次级文字
    static let textSecondary = dynamic(light: 0x71739B, dark: 0x9A9DAD)

    /// 主色：长春花靛紫
    static let accent = dynamic(light: 0x5D5FEF, dark: 0x7C7EF8)
    /// 主色上的文字（浅色模式白字，深色模式深底字）
    static let onAccent = dynamic(light: 0xFFFFFF, dark: 0x14151E)
    /// 主色浅底：次按钮背景
    static let accentSoft = dynamic(light: 0xE6E7FD, dark: 0x2E2F42)
    /// 主色深字：次按钮文字
    static let accentDeep = dynamic(light: 0x3B3ECF, dark: 0xB3B4FC)

    /// 点缀色：薄荷绿（选中胶囊、AI 标识等小面积）
    static let mint = dynamic(light: 0x0D9D62, dark: 0x4FD69B)
    /// 点缀色浅底
    static let mintSoft = dynamic(light: 0xDFF9EC, dark: 0x1E332B)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// 设计系统 · 间距刻度
enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// 设计系统 · 圆角刻度
enum AppRadius {
    static let card: CGFloat = 16
    static let control: CGFloat = 10
}

/// 设计系统 · 字体
enum AppFont {
    /// 页面大标题：粗壮无衬线，现代品牌感
    static let pageTitle = Font.system(size: 28, weight: .bold)
    /// 区块小标题
    static let sectionTitle = Font.system(size: 14, weight: .medium)
    static let body = Font.system(size: 16)
    static let caption = Font.system(size: 12)
}
