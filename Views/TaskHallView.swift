import SwiftUI

struct TaskHallView: View {
    @EnvironmentObject var store: SystemStore
    @State private var showAcceptConfirm: SharedTask?
    @State private var hallProof = ""
    @State private var showCompleteSheet = false
    @State private var selectedScope = 0

    private let scopes = ["可接取", "我的", "完成"]

    var body: some View {
        AppScreen(title: "大厅", subtitle: "把自己的任务发布出去，也接取其他系统的委托。") {
            hallSummary
            scopePicker

            if selectedScope == 0 {
                availableSection
            } else if selectedScope == 1 {
                mySection
            } else {
                completedSection
            }
        }
        .sheet(isPresented: $showCompleteSheet) { completeHallSheetView }
        .sheet(isPresented: $store.showTaskFeedback) { resultSheetView }
        .alert("接受任务", isPresented: .init(get: { showAcceptConfirm != nil }, set: { if !$0 { showAcceptConfirm = nil } })) {
            Button("确定接受") {
                if let task = showAcceptConfirm {
                    store.acceptHallTask(task)
                    selectedScope = 1
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let task = showAcceptConfirm {
                Text("接受「\(task.title)」？完成后获得 \(task.rewardCoins) 币和 \(task.rewardExp) 经验。")
            }
        }
    }

    private var publishableTasks: [SystemTask] {
        store.userData.tasks.filter { $0.status == .pending && !$0.isPublishedToHall }
    }

    private var availableTasks: [SharedTask] {
        store.hallTasks.filter { !$0.completed && $0.acceptedBy == nil }
    }

    private var completedTasks: [SharedTask] {
        store.hallTasks.filter { $0.completed }
    }

    private var hallSummary: some View {
        ClayCard {
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    MetricTile(value: "\(availableTasks.count)", label: "可接取", icon: "building.2.fill", color: DesignTokens.ColorTokens.accent)
                    MetricTile(value: "\(publishableTasks.count)", label: "可发布", icon: "paperplane.fill", color: DesignTokens.ColorTokens.primary)
                    MetricTile(value: "\(store.userData.completedHallTaskCount)", label: "已完成", icon: "checkmark.seal.fill", color: DesignTokens.ColorTokens.success)
                }
                if let accepted = store.userData.acceptedHallTask {
                    InfoRow(icon: "hourglass", title: accepted.title, subtitle: "进行中，来自 \(accepted.publisherName)", tint: DesignTokens.ColorTokens.warning, trailing: "\(accepted.rewardCoins)币")
                }
            }
        }
    }

    private var scopePicker: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(scopes.indices, id: \.self) { index in
                Button {
                    selectedScope = index
                } label: {
                    Text(scopes[index])
                        .font(DesignTokens.Typography.caption.weight(.semibold))
                        .foregroundColor(selectedScope == index ? .white : DesignTokens.ColorTokens.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selectedScope == index ? AnyView(DesignTokens.Gradients.primaryButton) : AnyView(DesignTokens.ColorTokens.surface))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .buttonStyle(ClayPressStyle())
            }
        }
    }

    private var availableSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            SectionHeader(title: "可接取任务")
            if availableTasks.isEmpty {
                FunEmptyState(icon: "tray", title: "暂无可接取任务", subtitle: "大厅任务都被接走了，稍后再来看看。")
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(Array(availableTasks.enumerated()), id: \.element.id) { index, task in
                        hallTaskRow(task).staggerEntrance(index: index)
                    }
                }
            }
        }
    }

    private var mySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            if let accepted = store.userData.acceptedHallTask {
                SectionHeader(title: "我接取的任务")
                acceptedTaskCard(accepted)
            } else {
                FunEmptyState(icon: "person.badge.plus", title: "还没有接取任务", subtitle: "去可接取列表挑一个适合今天完成的委托。")
            }

            SectionHeader(title: "可发布到大厅")
            if publishableTasks.isEmpty {
                FunEmptyState(icon: "paperplane", title: "暂无可发布任务", subtitle: "只有待提交的个人任务可以发布到大厅。")
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(publishableTasks) { task in
                        publishableRow(task)
                    }
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            SectionHeader(title: "已完成委托")
            if completedTasks.isEmpty {
                FunEmptyState(icon: "checkmark.seal", title: "暂无完成记录", subtitle: "完成大厅任务后会出现在这里。")
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(completedTasks) { task in
                        completedHallRow(task)
                    }
                }
            }
        }
    }

    private func acceptedTaskCard(_ task: SharedTask) -> some View {
        SummaryBand {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    StatusChip(text: "进行中", icon: "hourglass", color: .white)
                    Spacer()
                    Text("来自 \(task.publisherName)")
                        .font(DesignTokens.Typography.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.78))
                }
                Text(task.title)
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(.white)
                Text(task.description)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundColor(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    summaryReward(task)
                    Spacer()
                    ClaySmallButton(title: "提交完成", icon: "checkmark.seal.fill", action: { showCompleteSheet = true }, variant: .secondary)
                }
            }
        }
    }

    private func publishableRow(_ task: SystemTask) -> some View {
        ClayCard(cornerRadius: DesignTokens.Radius.lg, padding: DesignTokens.Spacing.md) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(DesignTokens.ColorTokens.primary)
                    .frame(width: 34, height: 34)
                    .background(DesignTokens.ColorTokens.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(DesignTokens.Typography.subheadline.weight(.semibold))
                        .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                    Text(task.description)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Label("大厅奖励 \(task.rewardCoins / 2) 币 + \(task.rewardExp / 2) 经验", systemImage: "gift.fill")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.ColorTokens.warning)
                }
                Spacer()
                ClaySmallButton(title: "发布", icon: "paperplane.fill", action: {
                    store.publishTaskToHall(task)
                    selectedScope = 0
                })
            }
        }
    }

    private func hallTaskRow(_ task: SharedTask) -> some View {
        ClayCard(cornerRadius: DesignTokens.Radius.lg, padding: DesignTokens.Spacing.md) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DesignTokens.ColorTokens.accent)
                    .frame(width: 34, height: 34)
                    .background(DesignTokens.ColorTokens.accentLight)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(task.title)
                            .font(DesignTokens.Typography.subheadline.weight(.semibold))
                            .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        StatusChip(text: "Lv.\(task.difficulty)", icon: "flame.fill", color: DesignTokens.ColorTokens.warning)
                    }
                    Text(task.description)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        summaryReward(task)
                            .foregroundColor(DesignTokens.ColorTokens.textMuted)
                        Spacer()
                        if store.userData.acceptedHallTask == nil {
                            ClaySmallButton(title: "接受", icon: "hand.raised.fill", action: { showAcceptConfirm = task }, variant: .accent)
                        } else {
                            StatusChip(text: "已有任务", icon: "lock.fill", color: DesignTokens.ColorTokens.textMuted)
                        }
                    }
                    Text("发布者 \(task.publisherName)")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.ColorTokens.textMuted)
                }
            }
        }
    }

    private func summaryReward(_ task: SharedTask) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Label("\(task.rewardCoins)币", systemImage: "bitcoinsign.circle.fill")
            Label("\(task.rewardExp)经验", systemImage: "bolt.fill")
        }
        .font(DesignTokens.Typography.caption2)
    }

    private func completedHallRow(_ task: SharedTask) -> some View {
        ClayCard(cornerRadius: DesignTokens.Radius.lg, padding: DesignTokens.Spacing.md) {
            InfoRow(
                icon: "checkmark.seal.fill",
                title: task.title,
                subtitle: "发布者 \(task.publisherName) · 完成者 \(task.acceptedBy ?? "未知")",
                tint: DesignTokens.ColorTokens.success,
                trailing: "\(task.rewardCoins)币"
            )
        }
    }

    private var completeHallSheetView: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Gradients.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        if let task = store.userData.acceptedHallTask {
                            InfoRow(icon: "building.2.fill", title: task.title, subtitle: task.description, tint: DesignTokens.ColorTokens.accent)
                                .padding(DesignTokens.Spacing.lg)
                                .background(DesignTokens.ColorTokens.surface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))

                            ClayCard {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                    Text("完成证明")
                                        .font(DesignTokens.Typography.caption.weight(.semibold))
                                        .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                                    TextField("描述你如何完成的...", text: $hallProof, axis: .vertical)
                                        .font(DesignTokens.Typography.body)
                                        .lineLimit(4...7)
                                        .padding(DesignTokens.Spacing.md)
                                        .background(DesignTokens.ColorTokens.background)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                                }
                            }

                            ClayButton(
                                title: "提交审核",
                                icon: "checkmark.seal.fill",
                                action: {
                                    Task {
                                        await store.completeHallTask(proof: hallProof)
                                        hallProof = ""
                                        showCompleteSheet = false
                                    }
                                },
                                isLoading: store.isLoading,
                                disabled: hallProof.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading
                            )
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("完成大厅任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        hallProof = ""
                        showCompleteSheet = false
                    }
                }
            }
        }
    }

    private var resultSheetView: some View {
        ZStack {
            DesignTokens.Gradients.background.ignoresSafeArea()
            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()
                if let result = store.lastTaskResult {
                    Image(systemName: result.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundColor(result.passed ? DesignTokens.ColorTokens.success : DesignTokens.ColorTokens.destructive)
                    Text(result.passed ? "大厅任务完成" : "未通过")
                        .font(DesignTokens.Typography.title)
                    Text(result.feedback)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(DesignTokens.Spacing.lg)
                        .background(DesignTokens.ColorTokens.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
                    ClayButton(title: "继续", icon: "arrow.right", action: {
                        store.showTaskFeedback = false
                        store.lastTaskResult = nil
                    })
                    .frame(maxWidth: 220)
                }
                Spacer()
            }
            .padding(DesignTokens.Spacing.xxl)
        }
    }
}

#Preview {
    TaskHallView().environmentObject(SystemStore())
}
