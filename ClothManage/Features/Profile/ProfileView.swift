import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var items: [ClothingItem]
    @Query private var outfits: [Outfit]
    @AppStorage("nickname") private var nickname = ""
    /// 图片质量选项（PRD 3.4.2）：影响之后新入库图片的压缩程度
    @AppStorage("imageQuality") private var imageQuality = "原图"

    @State private var storageBytes: Int64 = 0
    @State private var cleanResult: Int?
    @State private var showSubscription = false

    private var storageText: String {
        ByteCountFormatter.string(fromByteCount: storageBytes, countStyle: .file)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: AppSpacing.m) {
                        ZStack {
                            Circle()
                                .fill(AppColor.accentSoft)
                                .frame(width: 52, height: 52)
                            Text(nickname.isEmpty ? "衣" : String(nickname.prefix(1)))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(AppColor.accent)
                        }
                        TextField("点击设置昵称", text: $nickname)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
                .listRowBackground(AppColor.surface)

                Section {
                    LabeledContent("衣物总数", value: "\(items.count)")
                    LabeledContent("组合总数", value: "\(outfits.count)")
                    ForEach(ClothingCategory.allCases) { category in
                        let count = items.filter { $0.category == category }.count
                        if count > 0 {
                            LabeledContent(category.displayName, value: "\(count)")
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                } header: {
                    Text("衣橱统计")
                }
                .listRowBackground(AppColor.surface)

                Section {
                    LabeledContent("图片占用", value: storageText)
                    Picker("图片质量", selection: $imageQuality) {
                        Text("原图").tag("原图")
                        Text("压缩").tag("压缩")
                    }
                    Button("清理未使用的图片") {
                        cleanResult = cleanUnusedImages()
                        storageBytes = ImageStore.totalBytes()
                    }
                    .foregroundStyle(AppColor.accent)
                } header: {
                    Text("存储管理")
                } footer: {
                    Text("「压缩」仅影响之后新添加的图片；清理会删除不再被任何衣物或组合引用的图片文件。")
                }
                .listRowBackground(AppColor.surface)

                Section {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Text("衣橱会员")
                            Spacer()
                            Text("查看权益")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.accent)
                        }
                    }
                    LabeledContent("账号登录", value: "即将上线")
                        .foregroundStyle(AppColor.textSecondary)
                } header: {
                    Text("账号与订阅")
                }
                .listRowBackground(AppColor.surface)

                Section {
                    LabeledContent("版本", value: "1.0 开发版")
                        .foregroundStyle(AppColor.textSecondary)
                }
                .listRowBackground(AppColor.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("我的")
            .navigationDestination(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .onAppear {
                storageBytes = ImageStore.totalBytes()
                // 截图巡游：启动参数直达订阅页（正常使用不带该参数）
                if CommandLine.arguments.contains("--show-subscription") {
                    showSubscription = true
                }
            }
            .alert(
                "清理完成",
                isPresented: Binding(
                    get: { cleanResult != nil },
                    set: { if !$0 { cleanResult = nil } }
                )
            ) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("已删除 \(cleanResult ?? 0) 个未使用的图片文件")
            }
        }
    }

    /// 删除不再被任何衣物/组合引用的图片文件
    private func cleanUnusedImages() -> Int {
        var referenced = Set<String>()
        for item in items {
            referenced.insert(item.imageFileName)
            if let original = item.originalImageFileName {
                referenced.insert(original)
            }
        }
        for outfit in outfits {
            if let cover = outfit.coverImageFileName {
                referenced.insert(cover)
            }
        }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: ImageStore.directory.path)) ?? []
        var removed = 0
        for file in files where !referenced.contains(file) {
            ImageStore.delete(file)
            removed += 1
        }
        // 缩略图缓存一并清空，会按需重新生成
        ThumbnailStore.shared.clear()
        return removed
    }
}
