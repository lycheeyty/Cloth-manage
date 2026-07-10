import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var items: [ClothingItem]
    var onAddTapped: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.m),
        GridItem(.flexible(), spacing: AppSpacing.m),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ClothingItem.self) { item in
                ClothingDetailView(item: item)
            }
        }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                header
                LazyVGrid(columns: columns, spacing: AppSpacing.m) {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            ClothingCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    /// 顶部区域随内容一起滚动（PRD 3.2.2：滚动时顶部跟随滑走）
    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("我的衣橱")
                .font(AppFont.pageTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("\(items.count) 件单品")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.top, AppSpacing.l)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.l) {
            EmptyStateIcon(systemName: "tshirt")
            Text("衣橱还是空的")
                .font(AppFont.pageTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("拍下或上传你的第一件衣服\n开始整理你的专属衣橱")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("添加第一件衣服", action: onAddTapped)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, AppSpacing.s)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
