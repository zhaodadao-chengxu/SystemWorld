import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: SystemStore
    @State private var selectedTab = 0

    private let tabs: [(title: String, icon: String, filledIcon: String)] = [
        ("系统", "sparkles", "sparkles"),
        ("大厅", "building.2", "building.2.fill"),
        ("我的", "person.crop.circle", "person.crop.circle.fill")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    SystemHomeView()
                case 1:
                    TaskHallView()
                default:
                    ProfileStatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)

            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut(duration: 0.16), value: selectedTab)
        .alert("提示", isPresented: $store.showAppMessage) {
            Button("好") { store.showAppMessage = false }
        } message: {
            Text(store.appMessage)
        }
    }

    private var customTabBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(0..<tabs.count, id: \.self) { index in
                tabButton(index: index)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl)
                .stroke(DesignTokens.ColorTokens.border.opacity(0.35), lineWidth: 0.5)
        )
        .clayShadow(DesignTokens.Shadow.elevated(DesignTokens.ColorTokens.shadowTint))
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.md)
    }

    private func tabButton(index: Int) -> some View {
        let isSelected = selectedTab == index

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedTab = index
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? tabs[index].filledIcon : tabs[index].icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(tabs[index].title)
                    .font(DesignTokens.Typography.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : DesignTokens.ColorTokens.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? AnyView(DesignTokens.Gradients.primaryButton) : AnyView(Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel("\(tabs[index].title)标签")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    MainTabView().environmentObject(SystemStore())
}
