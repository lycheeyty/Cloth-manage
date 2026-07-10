import SwiftUI
import SwiftData

@main
struct ClothManageApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [ClothingItem.self, Outfit.self])
    }
}
