import SwiftUI

/// 分享图片生成 & 系统分享
struct ShareService {

    /// 生成分享卡片图片
    @MainActor
    static func generateShareImage(store: SystemStore) -> UIImage? {
        let lv = UserLevel.levelFor(exp: store.userData.totalExp)
        let card = ShareCardView(
            systemName: store.userData.systemName,
            level: lv.name,
            levelNum: lv.level,
            power: lv.fakePower,
            coins: store.userData.coins,
            completedTasks: store.userData.completedTasks,
            streak: store.userData.shareStreak
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - 分享卡片设计

struct ShareCardView: View {
    let systemName: String
    let level: String
    let levelNum: Int
    let power: String
    let coins: Int
    let completedTasks: Int
    let streak: Int

    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.11, blue: 0.28),
                    Color(red: 0.98, green: 0.44, blue: 0.52),
                    Color(red: 1.00, green: 0.80, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 装饰元素
            VStack(spacing: 0) {
                Spacer()

                // 图标
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.white)
                }

                Spacer().frame(height: 20)

                // 系统名
                Text(systemName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // 等级
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                    Text("Lv.\(levelNum) \(level)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 4)

                // 能力
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text(power)
                        .font(.system(size: 15, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 2)

                Spacer().frame(height: 24)

                // 统计
                HStack(spacing: 40) {
                    statItem(value: "\(coins)", label: "系统币", icon: "bitcoinsign.circle.fill")
                    statItem(value: "\(completedTasks)", label: "完成任务", icon: "checkmark.seal.fill")
                    statItem(value: "\(streak)", label: "分享天数", icon: "flame.fill")
                }

                Spacer().frame(height: 24)

                // 底部文字
                Text("来 SystemWorld 觉醒你的专属系统吧！")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }
            .padding(24)
        }
        .frame(width: 375, height: 500)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
