import SwiftUI

struct ProfileStatsView: View {
    @EnvironmentObject var store: SystemStore
    @State private var showTransfer = false
    @State private var transferAmount = ""
    @State private var transferTarget = ""
    @State private var showWithdraw = false
    @State private var withdrawAmount = ""
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var operationMessage = ""
    @State private var showOperationMessage = false

    var body: some View {
        AppScreen(title: "我的", subtitle: "查看等级、资产和系统历史。") {
            profileSummary
            levelCard
            aiSettingsCard
            operationsCard
            historyCard
        }
        .sheet(isPresented: $showTransfer) { transferSheet }
        .sheet(isPresented: $showWithdraw) { withdrawSheet }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage, "来 SystemWorld 觉醒你的专属系统吧！"])
            }
        }
        .alert("分享奖励", isPresented: $store.showShareReward) {
            Button("好") { store.showShareReward = false }
        } message: {
            Text(store.shareRewardMessage)
        }
        .alert("操作结果", isPresented: $showOperationMessage) {
            Button("好") { showOperationMessage = false }
        } message: {
            Text(operationMessage)
        }
    }

    private var profileSummary: some View {
        let lv = UserLevel.levelFor(exp: store.userData.totalExp)

        return SummaryBand {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(DesignTokens.ColorTokens.primary)
                        .frame(width: 58, height: 58)
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("修行者")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(.white)
                        Text(store.userData.systemName)
                            .font(DesignTokens.Typography.subheadline)
                            .foregroundColor(.white.opacity(0.78))
                            .lineLimit(2)
                    }
                    Spacer()
                    Text("Lv.\(lv.level)")
                        .font(DesignTokens.Typography.title3.monospacedDigit())
                        .foregroundColor(.white)
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    whiteMetric(value: "\(store.userData.coins)", label: "系统币")
                    whiteMetric(value: "\(store.userData.totalExp)", label: "经验")
                    whiteMetric(value: "\(store.userData.completedTasks)", label: "任务")
                    whiteMetric(value: "\(store.userData.shareStreak)", label: "分享")
                }

                shareButton
            }
        }
    }

    private func whiteMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(DesignTokens.Typography.headline.monospacedDigit())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(DesignTokens.Typography.caption2)
                .foregroundColor(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.sm)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private var shareButton: some View {
        let canShare = store.canShareToday

        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            shareImage = ShareService.generateShareImage(store: store)
            showShareSheet = true
            if canShare { _ = store.recordShare() }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 15, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("分享修行档案")
                        .font(DesignTokens.Typography.subheadline.weight(.semibold))
                    Text(canShare ? "每日首次分享 +20币 +50经验" : "今日已领取分享奖励")
                        .font(DesignTokens.Typography.caption2)
                        .opacity(0.78)
                }
                Spacer()
                Image(systemName: canShare ? "gift.fill" : "checkmark.circle.fill")
            }
            .foregroundColor(.white)
            .padding(DesignTokens.Spacing.md)
            .background(.white.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(ClayPressStyle())
    }

    private var levelCard: some View {
        let lv = UserLevel.levelFor(exp: store.userData.totalExp)

        return ClayCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionHeader(title: "等级")
                InfoRow(icon: "bolt.shield.fill", title: lv.name, subtitle: "超能力：\(lv.fakePower)", tint: DesignTokens.ColorTokens.success)
                Text(lv.powerDesc)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.ColorTokens.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

                if lv.level < 9 {
                    let next = UserLevel.all[lv.level + 1]
                    let pct = Double(store.userData.totalExp - lv.expRequired) / Double(max(1, next.expRequired - lv.expRequired))
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        AnimatedProgressBar(progress: min(max(pct, 0), 1), tint: DesignTokens.ColorTokens.success, height: 9)
                        HStack {
                            Text("距离 \(next.name)")
                            Spacer()
                            Text("\(store.userData.totalExp)/\(next.expRequired)")
                        }
                        .font(DesignTokens.Typography.caption2.monospacedDigit())
                        .foregroundColor(DesignTokens.ColorTokens.textMuted)
                    }
                } else {
                    StatusChip(text: "最高境界", icon: "crown.fill", color: DesignTokens.ColorTokens.warning)
                }
            }
        }
    }

    private var operationsCard: some View {
        ClayCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionHeader(title: "系统币")
                HStack(spacing: DesignTokens.Spacing.sm) {
                    operationButton(title: "转账", subtitle: "转给其他修行者", icon: "arrow.right", color: DesignTokens.ColorTokens.accent) {
                        showTransfer = true
                    }
                    operationButton(title: "提现", subtitle: "最低 100 币", icon: "banknote", color: DesignTokens.ColorTokens.success) {
                        showWithdraw = true
                    }
                }
            }
        }
    }

    private var aiSettingsCard: some View {
        ClayCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionHeader(title: "AI 联网")
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignTokens.ColorTokens.success)
                        .frame(width: 38, height: 38)
                        .background(DesignTokens.ColorTokens.success.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("由系统服务管理")
                            .font(DesignTokens.Typography.subheadline.weight(.semibold))
                            .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                        Text("系统、任务和审核会自动使用联网 AI，用户无需填写 Key。")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.ColorTokens.textSecondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private func operationButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(DesignTokens.Typography.subheadline.weight(.semibold))
                    .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                Text(subtitle)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.ColorTokens.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.md)
            .background(color.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(ClayPressStyle())
    }

    private var historyCard: some View {
        ClayCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionHeader(title: "系统历史")
                if store.userData.systemHistory.isEmpty {
                    Text("还没有绑定过系统")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.ColorTokens.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DesignTokens.Spacing.md)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.userData.systemHistory.reversed().enumerated()), id: \.element.id) { index, sys in
                            VStack(spacing: 0) {
                                InfoRow(
                                    icon: "sparkles",
                                    title: sys.name,
                                    subtitle: "\(sys.type) · \(sys.personality)",
                                    tint: DesignTokens.ColorTokens.primary,
                                    trailing: "\(sys.starRating)星"
                                )
                                .padding(.vertical, DesignTokens.Spacing.sm)

                                if index < store.userData.systemHistory.count - 1 {
                                    Divider().background(DesignTokens.ColorTokens.divider)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var transferSheet: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Gradients.background.ignoresSafeArea()
                VStack(spacing: DesignTokens.Spacing.lg) {
                    formField(title: "目标用户", placeholder: "输入用户名", text: $transferTarget)
                    formField(title: "转账数量", placeholder: "输入数量", text: $transferAmount, keyboard: .numberPad)
                    ClayButton(
                        title: "确认转账",
                        icon: "arrow.right",
                        action: {
                            let amount = Int(transferAmount) ?? 0
                            if store.transferCoins(amount: amount, toUser: transferTarget.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                operationMessage = "已转出 \(amount) 币。"
                                transferAmount = ""
                                transferTarget = ""
                                showTransfer = false
                                showOperationMessage = true
                            } else {
                                operationMessage = "转账失败，请检查用户名、金额和余额。"
                                showOperationMessage = true
                            }
                        },
                        disabled: transferTarget.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Int(transferAmount) ?? 0) <= 0
                    )
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("转账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        transferAmount = ""
                        transferTarget = ""
                        showTransfer = false
                    }
                }
            }
        }
    }

    private var withdrawSheet: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Gradients.background.ignoresSafeArea()
                VStack(spacing: DesignTokens.Spacing.lg) {
                    formField(title: "提现金额", placeholder: "最低 100 币", text: $withdrawAmount, keyboard: .numberPad)
                    ClayButton(
                        title: "申请提现",
                        icon: "banknote",
                        action: {
                            let amount = Int(withdrawAmount) ?? 0
                            operationMessage = store.withdraw(amount: amount)
                            withdrawAmount = ""
                            showWithdraw = false
                            showOperationMessage = true
                        },
                        disabled: (Int(withdrawAmount) ?? 0) < 100
                    )
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("提现")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        withdrawAmount = ""
                        showWithdraw = false
                    }
                }
            }
        }
    }

    private func formField(title: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        ClayCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.caption.weight(.semibold))
                    .foregroundColor(DesignTokens.ColorTokens.textPrimary)
                TextField(placeholder, text: text)
                    .font(DesignTokens.Typography.body)
                    .keyboardType(keyboard)
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.ColorTokens.background)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
        }
    }
}

#Preview {
    ProfileStatsView().environmentObject(SystemStore())
}
