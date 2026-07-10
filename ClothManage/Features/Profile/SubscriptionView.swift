import SwiftUI

/// 订阅页（首版 Mock，PRD 3.4.4）：仅展示权益对比 UI，不接入支付；
/// 「订阅」点击计数作为付费意愿埋点
struct SubscriptionView: View {
    @AppStorage("subscribeTapCount") private var subscribeTapCount = 0
    @State private var showComingSoon = false

    private struct Benefit: Identifiable {
        let id = UUID()
        let title: String
        let free: String
        let member: String
    }

    private let benefits: [Benefit] = [
        Benefit(title: "衣物数量", free: "最多 50 件", member: "无限"),
        Benefit(title: "穿搭组合", free: "最多 10 套", member: "无限"),
        Benefit(title: "AI 识别", free: "基础分类", member: "云端精准识别"),
        Benefit(title: "云端同步", free: "—", member: "多设备同步"),
        Benefit(title: "组合排版", free: "固定模板", member: "自由排版"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("衣橱会员")
                        .font(AppFont.pageTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("解锁完整的衣橱管理体验")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)
                }

                VStack(spacing: 0) {
                    HStack {
                        Text("权益")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("免费版")
                            .frame(width: 90)
                        Text("会员版")
                            .frame(width: 100)
                            .foregroundStyle(AppColor.accent)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(AppSpacing.m)
                    .background(AppColor.surfaceSecondary)

                    ForEach(benefits) { benefit in
                        HStack {
                            Text(benefit.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(AppColor.textPrimary)
                            Text(benefit.free)
                                .frame(width: 90)
                                .foregroundStyle(AppColor.textSecondary)
                            Text(benefit.member)
                                .frame(width: 100)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColor.accent)
                        }
                        .font(.system(size: 14))
                        .padding(AppSpacing.m)
                        .background(AppColor.surface)
                        if benefit.id != benefits.last?.id {
                            Divider()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))

                Button("订阅会员") {
                    subscribeTapCount += 1
                    showComingSoon = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: .infinity)

                Text("会员功能开发中，当前点击仅用于统计需求热度，不会产生任何扣费。")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.l)
        }
        .background(AppColor.background)
        .navigationTitle("订阅")
        .navigationBarTitleDisplayMode(.inline)
        .alert("会员功能即将上线", isPresented: $showComingSoon) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("感谢你的关注！我们已记录你的订阅意愿。")
        }
    }
}
