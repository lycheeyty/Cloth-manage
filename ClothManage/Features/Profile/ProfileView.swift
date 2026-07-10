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
                Section("衣橱统计") {
                    LabeledContent("衣物总数", value: "\(items.count)")
                    LabeledContent("组合总数", value: "\(outfits.count)")
                }

                if !items.isEmpty {
                    Section("分类分布") {
                        ForEach(ClothingCategory.allCases) { category in
                            let count = items.filter { $0.category == category }.count
                            if count > 0 {
                                LabeledContent(category.displayName, value: "\(count)")
                            }
                        }
                    }
                }

                Section("存储") {
                    LabeledContent("图片占用", value: storageText)
                }

                Section("账号与订阅") {
                    Text("登录与订阅功能即将上线")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("我的")
        }
    }
}
