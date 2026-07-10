import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WardrobeView(onAddTapped: { selectedTab = 1 })
                .tabItem { Label("衣橱", systemImage: "square.grid.2x2") }
                .tag(0)

            CaptureView(onPublished: { selectedTab = 0 })
                .tabItem { Label("添加", systemImage: "plus.circle.fill") }
                .tag(1)

            ProfileView()
                .tabItem { Label("我的", systemImage: "person") }
                .tag(2)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ClothingItem.self, Outfit.self], inMemory: true)
}
