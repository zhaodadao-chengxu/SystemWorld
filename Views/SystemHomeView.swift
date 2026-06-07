import SwiftUI
import PhotosUI

struct SystemHomeView: View {
    @EnvironmentObject var store: SystemStore
    @State private var taskProof = ""
    @State private var submittingTask: SystemTask?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var proofImageData: Data?
    @State private var showRerollConfirm = false
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if store.userData.currentSystem == nil {
                onboardingView
            } else {
                contentView
            }
        }
        .sheet(isPresented: $store.showSystemReveal) { revealSheetView }
        .sheet(isPresented: $store.showTaskFeedback) { resultSheetView }
        .sheet(item: $submittingTask) { submitSheetView($0) }
        .alert("突破！", isPresented: $store.showLevelUp) {
            Button("太棒了") { store.showLevelUp = false }
        } message: {
            if let lv = store.newLevel { Text("晋升 \(lv.name)，获得 \(lv.fakePower)") }
        }
        .confirmationDialog("重随系统需要 \(store.rerollCost) 系统币，今日剩余 \(store.remainingRerollsToday) 次。更换会清除当前本地任务。", isPresented: $showRerollConfirm, titleVisibility: .visible) {
            Button("花费 \(store.rerollCost) 币重随", role: .destructive) {
                Task { await store.rerollSystem() }
            }
            Button("取消", role: .cancel) {}
        }
        .onReceive(ticker) { value in
            now = value
        }
    }

    private var onboardingView: some View {
        ZStack {
            DesignTokens.Gradients.background.ignoresSafeArea()
            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()
                BouncyIcon(systemName: "sparkles", color: DesignTokens.ColorTokens.primary, size: 48)
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("SystemWorld")
                        .font(DesignTokens.Typography.largeTitle)
                        .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                    Text("随机觉醒一个专属系统，接受它发布的限时指令来升级你的虚拟修行档案。")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ClayButton(
                    title: store.isLoading ? "觉醒中" : "觉醒系统",
                    icon: "sparkles",
                    action: { Task { await store.generateSystem() } },
                    variant: .primary,
                    isLoading: store.isLoading,
                    disabled: store.isLoading
                )
                .frame(maxWidth: 260)
                Spacer()
            }
            .padding(DesignTokens.Spacing.xxxl)
        }
    }

    private var contentView: some View {
        let sys = store.userData.currentSystem!
        let lv = UserLevel.levelFor(exp: store.userData.totalExp)

        return AppScreen(title: "系统", subtitle: "当前绑定、任务倒计时和升级进度。") {
            systemSummary(sys, lv)
            commandPanel(sys)
            levelProgress(lv)
            taskSection
        }
        .refreshable {
            if store.canGenerateTask { await store.generateTask() }
        }
    }

    private func systemSummary(_ sys: NovelSystem, _ lv: UserLevel) -> some View {
        SummaryBand {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                            .fill(.white.opacity(0.16))
                        Text(sys.icon)
                            .font(.system(size: 42))
                    }
                    .frame(width: 74, height: 74)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("已绑定主系统")
                            .font(DesignTokens.Typography.caption.weight(.bold))
                            .foregroundColor(.white.opacity(0.68))
                        Text(sys.name)
                            .font(.system(.title, design: .rounded).weight(.black))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        StarRating(rating: sys.starRating, maxStars: 5, size: 16)
                    }
                    Spacer()
                    Button {
                        showRerollConfirm = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("\(store.rerollCost)币")
                                .font(DesignTokens.Typography.caption2.weight(.bold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 52, height: 48)
                        .background(.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }
                    .buttonStyle(ClayPressStyle())
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(sys.intro)
                        .font(DesignTokens.Typography.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        summaryChip(sys.type, icon: "tag.fill")
                        summaryChip(sys.personality, icon: "theatermasks.fill")
                        summaryChip(sys.specialty, icon: "scope")
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(.white.opacity(0.11))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))

                HStack(spacing: DesignTokens.Spacing.sm) {
                    systemMetric("Lv.\(lv.level)", lv.name, icon: "bolt.fill")
                    systemMetric("\(store.userData.coins)", "系统币", icon: "bitcoinsign.circle.fill")
                    systemMetric("\(store.remainingRerollsToday)", "今日重随", icon: "arrow.triangle.2.circlepath")
                }

                ClayButton(
                    title: taskClaimButtonTitle,
                    icon: "plus",
                    action: { Task { await store.generateTask() } },
                    variant: .secondary,
                    isLoading: store.isLoading,
                    disabled: store.isLoading || !store.canGenerateTask
                )
            }
        }
    }

    private var taskClaimButtonTitle: String {
        if store.isLoading { return "生成中" }
        if store.canGenerateTask { return "领取系统任务" }
        let remaining = store.taskClaimCooldownRemaining
        if remaining > 0 { return "冷却 \(SystemStore.durationText(remaining))" }
        return "任务进行中"
    }

    private func systemMetric(_ value: String, _ label: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(DesignTokens.Typography.caption.weight(.bold))
                Text(label).font(DesignTokens.Typography.caption2)
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .frame(height: 42)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func commandPanel(_ sys: NovelSystem) -> some View {
        ClayCard(cornerRadius: DesignTokens.Radius.lg, padding: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Label("系统指令", systemImage: "terminal.fill")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                    Spacer()
                    StatusChip(text: sys.type, icon: "sparkles", color: DesignTokens.ColorTokens.primary)
                }
                HStack(spacing: DesignTokens.Spacing.sm) {
                    MetricTile(value: "\(store.userData.tasks.filter { Calendar.current.isDateInToday($0.createdAt) }.count)/5", label: "今日任务", icon: "list.bullet.clipboard.fill", color: DesignTokens.ColorTokens.primary)
                    MetricTile(value: store.activeTask == nil ? "空闲" : "执行中", label: "任务槽", icon: "timer", color: store.activeTask == nil ? DesignTokens.ColorTokens.success : DesignTokens.ColorTokens.warning)
                    MetricTile(value: store.taskClaimCooldownRemaining > 0 ? SystemStore.durationText(store.taskClaimCooldownRemaining) : "可领取", label: "冷却", icon: "hourglass", color: DesignTokens.ColorTokens.accent)
                }
                if let reason = store.taskClaimBlockReason {
                    Text(reason)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func summaryChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(text).font(DesignTokens.Typography.caption2.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .frame(height: 24)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }

    private func levelProgress(_ lv: UserLevel) -> some View {
        ClayCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lv.fakePower)
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                        Text(lv.powerDesc)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    CoinBadge(amount: store.userData.coins)
                }

                if lv.level < 9 {
                    let next = UserLevel.all[lv.level + 1]
                    let pct = Double(store.userData.totalExp - lv.expRequired) / Double(max(1, next.expRequired - lv.expRequired))
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        AnimatedProgressBar(progress: min(max(pct, 0), 1), tint: DesignTokens.ColorTokens.success, height: 9)
                        HStack {
                            Text("\(store.userData.totalExp) / \(next.expRequired) EXP")
                            Spacer()
                            Text("下一级 \(next.name)")
                        }
                        .font(DesignTokens.Typography.caption2.monospacedDigit())
                        .foregroundColor(DesignTokens.ColorTokens.textMuted)
                    }
                } else {
                    StatusChip(text: "已达最高境界", icon: "crown.fill", color: DesignTokens.ColorTokens.warning)
                }
            }
        }
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            SectionHeader(title: "任务日志")
            if store.userData.tasks.isEmpty {
                FunEmptyState(
                    icon: "tray",
                    title: "还没有任务",
                    subtitle: "领取一个任务，把今天变成可升级的一天。",
                    action: { Task { await store.generateTask() } },
                    actionLabel: "领取任务"
                )
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(Array(store.userData.tasks.prefix(12).enumerated()), id: \.element.id) { index, task in
                        taskRow(task).staggerEntrance(index: index)
                    }
                }
            }
        }
    }

    private func taskRow(_ task: SystemTask) -> some View {
        ClayCard(cornerRadius: DesignTokens.Radius.lg, padding: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    Image(systemName: taskStatusIcon(task.status))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(taskStatusColor(task.status))
                        .frame(width: 34, height: 34)
                        .background(taskStatusColor(task.status).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(task.title)
                                .font(DesignTokens.Typography.subheadline.weight(.semibold))
                                .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            StatusChip(text: taskStatusText(task), icon: taskStatusIcon(task.status), color: taskStatusColor(task.status))
                        }

                        Text(task.aiFeedback ?? task.description)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Label("难度\(task.difficulty)", systemImage: "flame.fill")
                            Label("\(task.rewardCoins)币", systemImage: "bitcoinsign.circle.fill")
                            Label("\(task.rewardExp)经验", systemImage: "bolt.fill")
                            if task.isPublishedToHall {
                                Label("大厅", systemImage: "building.2.fill")
                            }
                            Spacer()
                            if task.status == .pending {
                                ClaySmallButton(title: "提交", icon: "arrow.up.doc.fill", action: { submittingTask = task })
                            }
                        }
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.ColorTokens.textMuted)
                    }
                }
            }
        }
    }

    private func taskStatusText(_ task: SystemTask) -> String {
        switch task.status {
        case .pending:
            if let deadline = task.deadline {
                return "剩 \(SystemStore.durationText(deadline.timeIntervalSince(now)))"
            }
            return "待提交"
        case .submitted: return "审核中"
        case .completed: return "完成"
        case .failed: return "未通过"
        case .expired: return "已失效"
        }
    }

    private func taskStatusColor(_ status: SystemTask.TaskStatus) -> Color {
        switch status {
        case .pending: return DesignTokens.ColorTokens.primary
        case .submitted: return DesignTokens.ColorTokens.accent
        case .completed: return DesignTokens.ColorTokens.success
        case .failed: return DesignTokens.ColorTokens.destructive
        case .expired: return DesignTokens.ColorTokens.textMuted
        }
    }

    private func taskStatusIcon(_ status: SystemTask.TaskStatus) -> String {
        switch status {
        case .pending: return "doc.text"
        case .submitted: return "hourglass"
        case .completed: return "checkmark.seal.fill"
        case .failed: return "xmark.seal.fill"
        case .expired: return "clock.badge.xmark.fill"
        }
    }

    private var revealSheetView: some View {
        ZStack {
            DesignTokens.Gradients.background.ignoresSafeArea()
            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()
                BouncyIcon(systemName: "sparkles", color: DesignTokens.ColorTokens.primary, size: 44)
                if let sys = store.userData.currentSystem {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("系统绑定成功")
                            .font(DesignTokens.Typography.title2)
                        Text(sys.name)
                            .font(DesignTokens.Typography.largeTitle)
                            .foregroundColor(DesignTokens.ColorTokens.primary)
                            .multilineTextAlignment(.center)
                        StarRating(rating: sys.starRating, maxStars: 5, size: 18)
                    }
                    Text(sys.intro)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(DesignTokens.Spacing.lg)
                        .background(DesignTokens.ColorTokens.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
                }
                ClayButton(title: "开始修行", icon: "arrow.right", action: { store.showSystemReveal = false })
                    .frame(maxWidth: 220)
                Spacer()
            }
            .padding(DesignTokens.Spacing.xxl)
        }
    }

    private func submitSheetView(_ task: SystemTask) -> some View {
        NavigationStack {
            ZStack {
                DesignTokens.Gradients.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        InfoRow(icon: "doc.text", title: task.title, subtitle: task.description, tint: DesignTokens.ColorTokens.primary)
                            .padding(DesignTokens.Spacing.lg)
                            .background(DesignTokens.ColorTokens.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))

                        ClayCard {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("完成证明")
                                    .font(DesignTokens.Typography.caption.weight(.semibold))
                                    .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                                TextField("描述你如何完成的...", text: $taskProof, axis: .vertical)
                                    .font(DesignTokens.Typography.body)
                                    .lineLimit(4...7)
                                    .padding(DesignTokens.Spacing.md)
                                    .background(DesignTokens.ColorTokens.background)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                            }
                        }

                        ClayCard {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("图片证明")
                                    .font(DesignTokens.Typography.caption.weight(.semibold))
                                    .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    HStack {
                                        Image(systemName: proofImageData == nil ? "photo.badge.plus" : "photo.fill")
                                        Text(proofImageData == nil ? "选择图片，可选" : "已选择图片")
                                        Spacer()
                                        if proofImageData != nil { Image(systemName: "checkmark.circle.fill") }
                                    }
                                    .font(DesignTokens.Typography.subheadline.weight(.semibold))
                                    .foregroundColor(proofImageData == nil ? DesignTokens.ColorTokens.primary : DesignTokens.ColorTokens.success)
                                    .padding(DesignTokens.Spacing.md)
                                    .background(DesignTokens.ColorTokens.background)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                                }
                                .onChange(of: selectedPhoto) { _, item in
                                    Task {
                                        if let data = try? await item?.loadTransferable(type: Data.self) {
                                            proofImageData = data
                                        }
                                    }
                                }
                                if proofImageData != nil {
                                    Button("清除图片") {
                                        selectedPhoto = nil
                                        proofImageData = nil
                                    }
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.ColorTokens.destructive)
                                }
                            }
                        }

                        ClayButton(
                            title: "提交审核",
                            icon: "checkmark.seal.fill",
                            action: {
                                Task {
                                    await store.submitTask(task, proof: taskProof, imageData: proofImageData)
                                    taskProof = ""
                                    proofImageData = nil
                                    selectedPhoto = nil
                                    submittingTask = nil
                                }
                            },
                            isLoading: store.isLoading,
                            disabled: taskProof.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading
                        )
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("提交任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        submittingTask = nil
                        taskProof = ""
                        proofImageData = nil
                        selectedPhoto = nil
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
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text(result.passed ? "任务完成" : "未通过")
                            .font(DesignTokens.Typography.title)
                            .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                        Text(result.feedback)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(DesignTokens.ColorTokens.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))

                    if result.passed {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            StatusChip(text: "+\(result.task.rewardCoins)币", icon: "bitcoinsign.circle.fill", color: DesignTokens.ColorTokens.warning)
                            StatusChip(text: "+\(result.task.rewardExp)经验", icon: "bolt.fill", color: DesignTokens.ColorTokens.success)
                        }
                    }
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
    SystemHomeView().environmentObject(SystemStore())
}
