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
    @State private var headerHeight: CGFloat = 140
    /// 多选模式（创建组合，PRD 3.3.1）
    @State private var isSelecting = false
    @State private var selectedItems: [ClothingItem] = []
    @State private var showCompose = false
    var onAddTapped: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.m),
        GridItem(.flexible(), spacing: AppSpacing.m),
    ]

    private var filterOptions: [String] {
        ["全部", "组合"] + ClothingCategory.allCases.map(\.displayName)
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
                    content
                }
            }
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(isSelecting ? .hidden : .automatic, for: .tabBar)
            .safeAreaInset(edge: .bottom) {
                if isSelecting {
                    selectionBar
                }
            }
            .navigationDestination(for: ClothingItem.self) { item in
                ClothingDetailView(item: item)
            }
            .navigationDestination(for: Outfit.self) { outfit in
                OutfitDetailView(outfit: outfit)
            }
        }
        .sheet(isPresented: $showCompose) {
            OutfitComposeView(items: selectedItems) {
                exitSelection()
            }
        }
    }

    /// 顶栏悬浮在内容上方，背景为线性渐隐模糊；内容从其下方滚过
    private var content: some View {
        ZStack(alignment: .top) {
            feed
            if showHeader {
                header
                    .background(headerBlurBackground)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: WardrobeHeaderHeightKey.self,
                                value: proxy.size.height
                            )
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onPreferenceChange(WardrobeHeaderHeightKey.self) { headerHeight = $0 }
    }

    /// 线性模糊：上实下透，避免实色背景生硬遮挡卡片
    private var headerBlurBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .padding(.bottom, -28)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.72),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    // MARK: - 顶部区域

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(isSelecting ? "选择单品" : "我的衣橱")
                        .font(AppFont.pageTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(isSelecting
                         ? "选 2–8 件创建穿搭组合"
                         : "\(items.count) 件单品 · \(outfits.count) 套组合")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                if !isSelecting {
                    Button {
                        enterSelection()
                    } label: {
                        Label("创建组合", systemImage: "square.on.square")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.accentDeep)
                            .padding(.horizontal, AppSpacing.m)
                            .padding(.vertical, AppSpacing.s)
                            .background(AppColor.accentSoft, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.l)

            if !isSelecting {
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
        }
        .padding(.top, AppSpacing.s)
        .padding(.bottom, AppSpacing.m)
    }

    // MARK: - Feed

    private var feed: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.m) {
                    ForEach(entries) { entry in
                        switch entry {
                        case .item(let item):
                            itemCell(item)
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                        case .outfit(let outfit):
                            outfitCell(outfit)
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                        }
                    }
                }
                .id("wardrobeTop")
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: items.count + outfits.count)
                .padding(.top, headerHeight + AppSpacing.s)
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
            // 新内容入库后回到顶部，配合入场动画定位新卡片（PRD 3.1.3）
            .onChange(of: items.count + outfits.count) { old, new in
                if new > old {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollProxy.scrollTo("wardrobeTop", anchor: .top)
                    }
                }
            }
        }
        .coordinateSpace(name: "wardrobeScroll")
        .onPreferenceChange(WardrobeScrollOffsetKey.self) { offset in
            let delta = offset - lastOffset
            // 向下滚且已离开顶部 → 收起顶栏；向上滚 → 展开
            if delta < -12, offset < -40, showHeader, !isSelecting {
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

    @ViewBuilder
    private func itemCell(_ item: ClothingItem) -> some View {
        if isSelecting {
            Button {
                toggleSelection(item)
            } label: {
                ClothingCard(item: item)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .stroke(isSelected(item) ? AppColor.accent : .clear, lineWidth: 2.5)
                    }
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: isSelected(item) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected(item) ? AppColor.accent : AppColor.textSecondary)
                            .background(Circle().fill(AppColor.surface.opacity(0.9)))
                            .padding(AppSpacing.s)
                    }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: item) {
                ClothingCard(item: item)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func outfitCell(_ outfit: Outfit) -> some View {
        if isSelecting {
            // 组合不能被选入组合，多选模式下置灰
            OutfitCard(outfit: outfit)
                .opacity(0.35)
        } else {
            NavigationLink(value: outfit) {
                OutfitCard(outfit: outfit)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 多选模式

    private var selectionBar: some View {
        VStack(spacing: AppSpacing.s) {
            if !selectedItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.s) {
                        ForEach(selectedItems) { item in
                            ThumbnailImage(fileName: item.imageFileName)
                                .frame(width: 44, height: 44)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))
                                .onTapGesture { toggleSelection(item) }
                        }
                    }
                    .padding(.horizontal, AppSpacing.l)
                }
            }
            HStack(spacing: AppSpacing.m) {
                Button("取消") { exitSelection() }
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text("已选 \(selectedItems.count)/8")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Button("下一步") { showCompose = true }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedItems.count < 2)
                    .opacity(selectedItems.count < 2 ? 0.5 : 1)
            }
            .padding(.horizontal, AppSpacing.l)
        }
        .padding(.vertical, AppSpacing.s)
        .background(.bar)
    }

    private func isSelected(_ item: ClothingItem) -> Bool {
        selectedItems.contains { $0.persistentModelID == item.persistentModelID }
    }

    private func toggleSelection(_ item: ClothingItem) {
        if let index = selectedItems.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) {
            selectedItems.remove(at: index)
        } else if selectedItems.count < 8 {
            selectedItems.append(item)
        }
    }

    private func enterSelection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelecting = true
            showHeader = true
            // 多选针对单品，切出「组合」筛选
            if filter == "组合" { filter = "全部" }
        }
    }

    private func exitSelection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelecting = false
            selectedItems = []
        }
    }

    // MARK: - 空状态

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
        EmptyStagePage(
            icon: "tshirt",
            title: "衣橱还是空的",
            subtitle: "拍下或上传你的第一件衣服\n开始整理你的专属衣橱"
        ) {
            Button("添加第一件衣服", action: onAddTapped)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, AppSpacing.s)
        }
    }
}

private struct WardrobeScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct WardrobeHeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 140
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
