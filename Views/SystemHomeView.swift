import SwiftUI
import PhotosUI

struct SystemHomeView: View {
    @EnvironmentObject var store: SystemStore
    @State private var taskProof = ""
    @State private var submittingTask: SystemTask?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var proofImageData: Data?
    @State private var showRerollConfirm = false

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
        .confirmationDialog("更换系统将清除所有本地任务，确定继续？", isPresented: $showRerollConfirm, titleVisibility: .visible) {
            Button("确定更换", role: .destructive) {
                Task { await store.rerollSystem() }
            }
            Button("取消", role: .cancel) {}
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
                    Text("随机觉醒一个专属系统，用日常任务升级你的虚拟修行档案。")
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

        return AppScreen(title: "系统", subtitle: "今日状态、任务和升级进度都在这里。") {
            systemSummary(sys, lv)
            levelProgress(lv)
            taskSection
        }
        .refreshable {
            if store.canGenerateTask { await store.generateTask() }
        }
    }

    private func systemSummary(_ sys: NovelSystem, _ lv: UserLevel) -> some View {
        SummaryBand {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(sys.name)
                            .font(DesignTokens.Typography.title2)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            StarRating(rating: sys.starRating, maxStars: 5)
                            Text(sys.type)
                                .font(DesignTokens.Typography.caption.weight(.semibold))
                                .foregroundColor(.white.opacity(0.78))
                        }
                    }
                    Spacer()
                    Button {
                        showRerollConfirm = true
                    } label: {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }
                    .buttonStyle(ClayPressStyle())
                }

                Text(sys.intro)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundColor(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    summaryChip(sys.personality, icon: "theatermasks.fill")
                    summaryChip(sys.specialty, icon: "scope")
                    Spacer()
                    Text("Lv.\(lv.level) \(lv.name)")
                        .font(DesignTokens.Typography.caption.weight(.bold))
                        .foregroundColor(.white)
                }

                ClayButton(
                    title: store.isLoading ? "生成中" : "领取任务",
                    icon: "plus",
                    action: { Task { await store.generateTask() } },
                    variant: .secondary,
                    isLoading: store.isLoading,
                    disabled: store.isLoading
                )
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
                            StatusChip(text: taskStatusText(task.status), icon: taskStatusIcon(task.status), color: taskStatusColor(task.status))
                        }

                        Text(task.aiFeedback ?? task.description)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: DesignTokens.Spacing.sm) {
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

    private func taskStatusText(_ status: SystemTask.TaskStatus) -> String {
        switch status {
        case .pending: return "待提交"
        case .submitted: return "审核中"
        case .completed: return "完成"
        case .failed: return "未通过"
        }
    }

    private func taskStatusColor(_ status: SystemTask.TaskStatus) -> Color {
        switch status {
        case .pending: return DesignTokens.ColorTokens.primary
        case .submitted: return DesignTokens.ColorTokens.accent
        case .completed: return DesignTokens.ColorTokens.success
        case .failed: return DesignTokens.ColorTokens.destructive
        }
    }

    private func taskStatusIcon(_ status: SystemTask.TaskStatus) -> String {
        switch status {
        case .pending: return "doc.text"
        case .submitted: return "hourglass"
        case .completed: return "checkmark.seal.fill"
        case .failed: return "xmark.seal.fill"
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
