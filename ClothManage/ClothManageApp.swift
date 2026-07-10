import SwiftUI
import SwiftData

@main
struct ClothManageApp: App {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(for: ClothingItem.self, Outfit.self)
        // 截图/演示用启动参数，正常使用不会带这些参数
        let args = CommandLine.arguments
        if args.contains("--wipe-data") {
            DemoSeeder.wipe(container: container)
        } else if args.contains("--seed-demo") {
            DemoSeeder.wipe(container: container)
            DemoSeeder.seed(container: container)
        }
    }

    private var forcedScheme: ColorScheme? {
        if CommandLine.arguments.contains("--force-dark") { return .dark }
        if CommandLine.arguments.contains("--force-light") { return .light }
        return nil
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(forcedScheme)
        }
        .modelContainer(container)
    }
}
