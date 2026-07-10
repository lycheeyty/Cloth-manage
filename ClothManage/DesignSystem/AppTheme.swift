import SwiftUI
import UIKit

/// 设计系统 · 颜色令牌（自动适配深色模式）
/// 基调：暖白纸感底色 + 陶土色点缀，突出衣物图片本身
enum AppColor {
    /// 页面底色
    static let background = dynamic(light: 0xF7F4EF, dark: 0x191817)
    /// 卡片、输入框等表面
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x262421)
    /// 次级表面：占位、未选中态
    static let surfaceSecondary = dynamic(light: 0xEFEAE2, dark: 0x33302C)
    /// 主文字
    static let textPrimary = dynamic(light: 0x2D2A26, dark: 0xF2EFEA)
    /// 次级文字
    static let textSecondary = dynamic(light: 0x8A847B, dark: 0xA39D93)
    /// 主题色：陶土色
    static let accent = dynamic(light: 0xC06E4A, dark: 0xD98A66)
    /// 主题色浅底：选中态背景
    static let accentSoft = dynamic(light: 0xF3E3DA, dark: 0x4A342A)

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
    /// 页面大标题：衬线体，杂志编辑感
    static let pageTitle = Font.system(size: 28, weight: .semibold, design: .serif)
    /// 区块小标题
    static let sectionTitle = Font.system(size: 14, weight: .medium)
    static let body = Font.system(size: 16)
    static let caption = Font.system(size: 12)
}
