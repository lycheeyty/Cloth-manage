import SwiftUI
import SwiftData

/// 混排条目：单品与组合在瀑布流中混排展示（PRD 3.3.2 决策 2）
enum WardrobeEntry: Identifiable {
    case item(ClothingItem)
    case outfit(Outfit)

    var id: PersistentIdentifier {
        switch self {
        case .item(let item): return item.persistentModelID
        case .outfit(let outfit): return outfit.persistentModelID
        }
    }

    var createdAt: Date {
        switch self {
        case .item(let item): return item.createdAt
        case .outfit(let outfit): return outfit.createdAt
        }
    }
}

struct WardrobeView: View {
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var items: [ClothingItem]
    @Query(sort: \Outfit.createdAt, order: .reverse) private var outfits: [Outfit]
    /// 筛选选择持久化（PRD 3.2.3）
    @AppStorage("wardrobeFilter") private var filter = "全部"
    @State private var showHeader = true
    @State private var lastOffset: CGFloat = 0
    var onAddTapped: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.m),
        GridItem(.flexible(), spacing: AppSpacing.m),
    ]

    private var filterOptions: [String] {
        ["全部"] + ClothingCategory.allCases.map(\.displayName) + ["组合"]
    }

    private var entries: [WardrobeEntry] {
        switch filter {
        case "全部":
            let all = items.map(WardrobeEntry.item) + outfits.map(WardrobeEntry.outfit)
            return all.sorted { $0.createdAt > $1.createdAt }
        case "组合":
            return outfits.map(WardrobeEntry.outfit)
        default:
            return items
                .filter { $0.category.displayName == filter }
                .map(WardrobeEntry.item)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty && outfits.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        if showHeader {
                            header
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        feed
                    }
                }
            }
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ClothingItem.self) { item in
                ClothingDetailView(item: item)
            }
            .navigationDestination(for: Outfit.self) { outfit in
                OutfitDetailView(outfit: outfit)
            }
        }
    }

    /// 顶部区域：标题 + 分类筛选，随滚动方向显隐（PRD 3.2.2）
    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("我的衣橱")
                    .font(AppFont.pageTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text("\(items.count) 件单品 · \(outfits.count) 套组合")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.l)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.s) {
                    ForEach(filterOptions, id: \.self) { option in
                        CategoryChip(
                            title: option,
                            isSelected: filter == option,
                            action: { filter = option }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.l)
            }
        }
        .padding(.top, AppSpacing.s)
        .padding(.bottom, AppSpacing.m)
    }

    private var feed: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.m) {
                ForEach(entries) { entry in
                    switch entry {
                    case .item(let item):
                        NavigationLink(value: item) {
                            ClothingCard(item: item)
                        }
                        .buttonStyle(.plain)
                    case .outfit(let outfit):
                        NavigationLink(value: outfit) {
                            OutfitCard(outfit: outfit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.bottom, AppSpacing.xl)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: WardrobeScrollOffsetKey.self,
                        value: proxy.frame(in: .named("wardrobeScroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "wardrobeScroll")
        .onPreferenceChange(WardrobeScrollOffsetKey.self) { offset in
            let delta = offset - lastOffset
            // 向下滚且已离开顶部 → 收起顶栏；向上滚 → 展开
            if delta < -12, offset < -40, showHeader {
                withAnimation(.easeInOut(duration: 0.2)) { showHeader = false }
            } else if delta > 12, !showHeader {
                withAnimation(.easeInOut(duration: 0.2)) { showHeader = true }
            }
            lastOffset = offset
        }
        .overlay {
            if entries.isEmpty {
                filteredEmptyState
            }
        }
    }

    private var filteredEmptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: filter == "组合" ? "square.grid.2x2" : "tshirt")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.textSecondary)
            Text(filter == "组合" ? "还没有创建过组合" : "这个分类下还没有衣物")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
        }
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

private struct WardrobeScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
