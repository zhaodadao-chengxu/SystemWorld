import SwiftUI

@main
struct SystemWorldApp: App {
    @StateObject private var store = SystemStore()

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 全局背景 — 确保 iPhone 17 Pro 全屏铺满，无黑边
                DesignTokens.Gradients.background
                    .ignoresSafeArea(.all)

                MainTabView()
                    .environmentObject(store)
            }
            .tint(DesignTokens.ColorTokens.primary)
            .preferredColorScheme(.light)
        }
    }
}
