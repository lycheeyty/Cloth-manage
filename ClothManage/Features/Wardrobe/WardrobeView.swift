import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var items: [ClothingItem]
    var onAddTapped: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items) { item in
                                NavigationLink(value: item) {
                                    ClothingCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("我的衣橱")
            .navigationDestination(for: ClothingItem.self) { item in
                ClothingDetailView(item: item)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("衣橱还是空的")
                .font(.headline)
            Text("拍下或上传你的第一件衣服，开始整理衣橱")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("添加第一件衣服", action: onAddTapped)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
