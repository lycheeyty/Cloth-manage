import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var items: [ClothingItem]
    @Query private var outfits: [Outfit]

    private var storageText: String {
        ByteCountFormatter.string(fromByteCount: ImageStore.totalBytes(), countStyle: .file)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("衣物总数", value: "\(items.count)")
                    LabeledContent("组合总数", value: "\(outfits.count)")
                } header: {
                    Text("衣橱统计")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .listRowBackground(AppColor.surface)

                if !items.isEmpty {
                    Section {
                        ForEach(ClothingCategory.allCases) { category in
                            let count = items.filter { $0.category == category }.count
                            if count > 0 {
                                LabeledContent(category.displayName, value: "\(count)")
                            }
                        }
                    } header: {
                        Text("分类分布")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .listRowBackground(AppColor.surface)
                }

                Section {
                    LabeledContent("图片占用", value: storageText)
                } header: {
                    Text("存储")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .listRowBackground(AppColor.surface)

                Section {
                    Text("登录与订阅功能即将上线")
                        .foregroundStyle(AppColor.textSecondary)
                } header: {
                    Text("账号与订阅")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .listRowBackground(AppColor.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("我的")
        }
    }
}
