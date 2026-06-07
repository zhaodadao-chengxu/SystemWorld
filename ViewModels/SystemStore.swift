import Foundation
import Combine
import SwiftUI

@MainActor
final class SystemStore: ObservableObject {
    @Published var userData = SystemUserData()
    @Published var isLoading = false
    @Published var showSystemReveal = false
    @Published var revealedSystem: NovelSystem? = nil
    @Published var showTaskFeedback = false
    @Published var lastTaskResult: (task: SystemTask, passed: Bool, feedback: String)? = nil
    @Published var showLevelUp = false
    @Published var newLevel: UserLevel? = nil
    @Published var showShareReward = false
    @Published var shareRewardMessage = ""
    @Published var showAppMessage = false
    @Published var appMessage = ""

    // 大厅模拟数据
    @Published var hallTasks: [SharedTask] = []

    private let key = "system_world_user_v2"
    private let hallKey = "system_world_hall_v1"
    private let reviewQuotaDateKey = "system_world_review_quota_date_v1"
    private let reviewQuotaCountKey = "system_world_review_quota_count_v1"
    private let maxDailyTasks = 5
    private let maxDailyReviews = 10
    private let taskCooldown: TimeInterval = 30 * 60
    private let maxDailyRerolls = 3
    private let renderAIBackendURL = URL(string: "https://systemworld-ai-zhaodadao.onrender.com/api/ai")!
    private let tencentAIBackendURL = URL(string: "http://43.128.42.179/api/ai")!
    private let cloudflareAIBackendURL = URL(string: "https://systemworld-ai-zhaodadao.420987231.workers.dev/api/ai")!
    private let localAIBackendURL = URL(string: "http://127.0.0.1:8787/api/ai")!
    private var lastAIErrorMessage: String?

    private var aiBackendURLs: [URL] {
        #if DEBUG
        [localAIBackendURL, tencentAIBackendURL, renderAIBackendURL, cloudflareAIBackendURL]
        #else
        [tencentAIBackendURL, renderAIBackendURL, cloudflareAIBackendURL]
        #endif
    }

    var isAIBackendConfigured: Bool {
        true
    }

    init() {
        load()
        loadHall()
        expireOverdueTasks()
    }

    // MARK: - 随机获得系统
    func generateSystem() async {
        isLoading = true
        defer { isLoading = false }

        let prompt = """
你是一个网络小说系统生成器。为你的用户随机生成一个独特的"系统"。系统可以是各种类型：
- 签到系/任务系/搞笑系/战斗系/养成系/氪金系/美食系/社恐系/或其他有趣类型

输出纯JSON：
{
  "name": "系统名称（中文，有网文风格）",
  "starRating": 1-5的整数,
  "type": "类型标签",
  "personality": "系统性格（傲娇/温柔/沙雕/冷酷/热血/吐槽/中二/腹黑等）",
  "intro": "一段有趣的系统自我介绍（30-50字）",
  "icon": "一个emoji表情",
  "specialty": "擅长领域"
}

系统名要有创意！五星概率约10%，一星约20%。
"""

        if let json = await askAI(operation: "generateSystem", prompt: prompt) {
            if let sys = parseSystem(from: json) {
                userData.currentSystem = sys
                userData.systemName = sys.name
                userData.systemHistory.append(sys)
                revealedSystem = sys
                showSystemReveal = true
                userData.rerollCount = 0
                save()
            } else {
                useFallbackSystem()
            }
        } else {
            useFallbackSystem()
            notify(aiUnavailableMessage(fallback: "已为你绑定一个本地系统。"))
        }
    }

    private func useFallbackSystem() {
        let systems = [
            NovelSystem(name: "万界摸鱼系统", star: 3, type: "搞笑系", personality: "沙雕逗比", intro: "叮！检测到宿主精神力不足，今日先从轻量任务开始逆袭。", icon: "🎣", specialty: "低压行动"),
            NovelSystem(name: "晨光自律系统", star: 4, type: "养成系", personality: "温柔坚定", intro: "绑定成功。每一次小小行动，都会被本系统记录为升级材料。", icon: "🌅", specialty: "习惯养成"),
            NovelSystem(name: "拖延清算系统", star: 3, type: "任务系", personality: "毒舌但靠谱", intro: "宿主拖延值过高，本系统将用小任务帮你夺回今日控制权。", icon: "⏱️", specialty: "推进事项"),
            NovelSystem(name: "社恐逆袭系统", star: 4, type: "社交系", personality: "鼓励型", intro: "不用一下子变外向，今天只需要完成一次轻微勇敢。", icon: "🫧", specialty: "社交破冰"),
            NovelSystem(name: "学霸充能系统", star: 3, type: "学习系", personality: "冷静理性", intro: "知识能量不足。完成专注任务，即可恢复学习引擎。", icon: "📚", specialty: "专注学习"),
            NovelSystem(name: "生活整理系统", star: 2, type: "生活系", personality: "细致耐心", intro: "环境即气场。清理一处混乱，就是给人生腾出一点空间。", icon: "🧺", specialty: "空间整理")
        ]
        let fallback = systems.randomElement()!
        userData.currentSystem = fallback
        userData.systemName = fallback.name
        userData.systemHistory.append(fallback)
        revealedSystem = fallback
        showSystemReveal = true
        save()
    }

    // MARK: - 重新随机系统（清除旧任务）
    var rerollCost: Int {
        min(150, 30 + currentRerollCount * 20)
    }

    var remainingRerollsToday: Int {
        max(0, maxDailyRerolls - currentRerollCount)
    }

    var canRerollSystem: Bool {
        remainingRerollsToday > 0 && userData.coins >= rerollCost && !isLoading
    }

    func rerollSystem() async {
        refreshRerollWindow()
        guard remainingRerollsToday > 0 else {
            notify("今日重随次数已用完，明天再换一个系统。")
            return
        }
        guard userData.coins >= rerollCost else {
            notify("系统币不足，重随需要 \(rerollCost) 币。")
            return
        }

        userData.coins -= rerollCost
        userData.rerollCount = currentRerollCount + 1
        userData.lastRerollDate = Self.dateKey(Date())
        userData.tasks.removeAll()       // ✅ 清除所有旧任务
        userData.currentSystem = nil
        userData.systemName = "未绑定"
        save()
        await generateSystem()
    }

    // MARK: - 生成任务
    var activeTask: SystemTask? {
        expireOverdueTasks()
        return userData.tasks.first { $0.status == .pending || $0.status == .submitted }
    }

    var canGenerateTask: Bool {
        expireOverdueTasks()
        guard activeTask == nil else { return false }
        guard userData.tasks.filter({ Calendar.current.isDateInToday($0.createdAt) }).count < maxDailyTasks else { return false }
        if latestTaskAllowsImmediateClaim { return true }
        guard let last = userData.lastTaskClaimAt else { return true }
        return Date().timeIntervalSince(last) >= taskCooldown
    }

    var taskClaimCooldownRemaining: TimeInterval {
        expireOverdueTasks()
        if activeTask != nil || latestTaskAllowsImmediateClaim { return 0 }
        guard let last = userData.lastTaskClaimAt else { return 0 }
        return max(0, taskCooldown - Date().timeIntervalSince(last))
    }

    var taskClaimBlockReason: String? {
        expireOverdueTasks()
        if let activeTask {
            return "先完成或等「\(activeTask.title)」失效后，再领取新任务。"
        }
        if userData.tasks.filter({ Calendar.current.isDateInToday($0.createdAt) }).count >= maxDailyTasks {
            return "今天最多领取 \(maxDailyTasks) 个任务，明天再继续修炼。"
        }
        let remaining = taskClaimCooldownRemaining
        if remaining > 0 {
            return "领取冷却中，还需 \(Self.durationText(remaining))。完成当前任务可立刻再领。"
        }
        return nil
    }

    func generateTask() async {
        guard let sys = userData.currentSystem else { return }
        guard canGenerateTask else {
            notify(taskClaimBlockReason ?? "暂时不能领取新任务。")
            return
        }
        isLoading = true; defer { isLoading = false }

        let level = UserLevel.levelFor(exp: userData.totalExp)
        let prompt = """
你是"\(sys.name)"系统（\(sys.personality)性格），宿主当前等级：\(level.name)。
系统类型：\(sys.type)。系统专长：\(sys.specialty)。系统自我介绍：\(sys.intro)
请以这个系统的口气发布一个高度匹配系统设定的现实任务，任务必须和系统类型、专长或性格强相关，不能泛泛而谈，不能叫"日常任务"。

输出纯JSON：
{
  "title": "任务标题（8-18字，带系统风格）",
  "description": "任务描述（以系统的口气，有趣一点，28-60字，必须说明具体行动）",
  "difficulty": 1-5,
  "rewardCoins": 由App规则决定,
  "rewardExp": 由App规则决定
}

任务要求：可以在现实生活中完成，运动/学习/社交/助人/自我提升等。有趣不无聊！
"""

        let generatedTask: SystemTask
        if let json = await askAI(operation: "generateTask", prompt: prompt), let task = parseTask(from: json, systemName: sys.name) {
            generatedTask = task
        } else {
            generatedTask = fallbackTask(for: sys.name)
            notify(aiUnavailableMessage(fallback: "已为你生成一个本地任务。"))
        }

        userData.tasks.insert(generatedTask, at: 0)
        userData.lastTaskDate = Self.dateKey(Date())
        userData.lastTaskClaimAt = Date()
        save()
    }

    // MARK: - 提交任务审核（支持图片证明）
    func submitTask(_ task: SystemTask, proof: String, imageData: Data? = nil) async {
        expireOverdueTasks()
        guard !isTaskExpired(task) else {
            finishTaskReview(task, proof: proof, imageData: imageData, passed: false, feedback: "任务倒计时已结束，本次任务失效。")
            return
        }
        guard consumeReviewQuota() else {
            finishTaskReview(task, proof: proof, imageData: imageData, passed: false, feedback: "今日审核次数已用完，请明天再提交。")
            return
        }
        guard isAllowedUserText(proof) else {
            finishTaskReview(task, proof: proof, imageData: imageData, passed: false, feedback: "证明内容不适合提交，请换一种更清楚的描述。")
            return
        }
        if let imageData, imageData.count > 4_000_000 {
            finishTaskReview(task, proof: proof, imageData: nil, passed: false, feedback: "图片太大了，请换一张更小的证明图。")
            return
        }
        guard let sys = userData.currentSystem else { return }
        isLoading = true; defer { isLoading = false }

        let hasImage = imageData != nil ? "（宿主附带了图片证明）" : ""
        let prompt = """
你是"\(sys.name)"系统（\(sys.personality)性格）。宿主提交了任务：
任务：\(task.title)
描述：\(task.description)
宿主文字证明：\(proof)\(hasImage)
请以系统的口气评估完成情况。输出纯JSON：
{"passed": true或false, "feedback": "有趣的评价反馈（20-40字）"}
"""

        if let json = await askAI(operation: "reviewTask", prompt: prompt, imageData: imageData),
           let data = cleanedJSON(json).data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let passed = dict["passed"] as? Bool ?? true
            let feedback = dict["feedback"] as? String ?? "任务完成！"
            finishTaskReview(task, proof: proof, imageData: imageData, passed: passed, feedback: feedback)
        } else {
            let passed = proof.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
            let feedback = passed ? "审核服务暂时不可用，已按文字证明完成基础审核。" : "证明太短了，补充完成过程后再提交。"
            finishTaskReview(task, proof: proof, imageData: imageData, passed: passed, feedback: feedback)
        }
    }

    // MARK: - 发布任务到大厅
    func publishTaskToHall(_ task: SystemTask) {
        guard let idx = userData.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let shared = SharedTask(task: task, publisherName: userData.systemName)
        userData.tasks[idx].isPublishedToHall = true
        userData.sharedTasks.append(shared)
        hallTasks.insert(shared, at: 0)  // 也加到全局大厅
        save(); saveHall()
    }

    // MARK: - 从大厅接受任务
    func acceptHallTask(_ shared: SharedTask) {
        guard userData.acceptedHallTask == nil else { return }
        if let idx = hallTasks.firstIndex(where: { $0.id == shared.id }) {
            hallTasks[idx].acceptedBy = userData.systemName
            userData.acceptedHallTask = hallTasks[idx]
        } else {
            var accepted = shared
            accepted.acceptedBy = userData.systemName
            userData.acceptedHallTask = accepted
        }
        save(); saveHall()
    }

    // MARK: - 完成大厅任务（分半奖励）
    func completeHallTask(proof: String, imageData: Data? = nil) async {
        guard let hallTask = userData.acceptedHallTask,
              let sys = userData.currentSystem else { return }
        guard consumeReviewQuota() else {
            finishHallReview(hallTask, passed: false, feedback: "今日审核次数已用完，请明天再提交。")
            return
        }
        guard isAllowedUserText(proof) else {
            finishHallReview(hallTask, passed: false, feedback: "证明内容不适合提交，请换一种更清楚的描述。")
            return
        }
        if let imageData, imageData.count > 4_000_000 {
            finishHallReview(hallTask, passed: false, feedback: "图片太大了，请换一张更小的证明图。")
            return
        }

        isLoading = true; defer { isLoading = false }

        let hasImage = imageData != nil ? "（宿主附带了图片证明，请结合图片判断）" : ""
        let prompt = """
你是"\(sys.name)"系统。宿主完成了一个从大厅接的任务：
任务：\(hallTask.title)
描述：\(hallTask.description)
证明：\(proof)\(hasImage)
评估完成情况。输出JSON：{"passed":true/false, "feedback":"评价"}
"""

        if let json = await askAI(operation: "reviewHallTask", prompt: prompt, imageData: imageData),
           let data = cleanedJSON(json).data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let passed = dict["passed"] as? Bool ?? true
            let feedback = dict["feedback"] as? String ?? "任务完成！"
            finishHallReview(hallTask, passed: passed, feedback: feedback)
        } else {
            let passed = proof.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
            let feedback = passed ? "审核服务暂时不可用，已按文字证明完成基础审核。" : "证明太短了，补充完成过程后再提交。"
            finishHallReview(hallTask, passed: passed, feedback: feedback)
        }
    }

    // MARK: - 每日分享奖励
    var canShareToday: Bool {
        userData.lastShareDate != Self.dateKey(Date())
    }

    func recordShare() -> Bool {
        guard canShareToday else { return false }
        userData.lastShareDate = Self.dateKey(Date())
        userData.shareStreak += 1
        userData.coins += 20
        userData.totalExp += 50
        shareRewardMessage = "分享成功！+20币 +50经验"
        showShareReward = true

        let lv = UserLevel.levelFor(exp: userData.totalExp)
        let oldLevel = UserLevel.levelFor(exp: userData.totalExp - 50)
        if lv.level > oldLevel.level { newLevel = lv; showLevelUp = true }

        save()
        return true
    }

    // MARK: - 转账
    func transferCoins(amount: Int, toUser: String) -> Bool {
        guard userData.coins >= amount, amount > 0 else { return false }
        userData.coins -= amount
        save(); return true
    }

    func withdraw(amount: Int) -> String {
        guard userData.coins >= amount, amount >= 100 else { return "最低提现100币" }
        userData.coins -= amount
        save()
        return "已提交提现\(amount)币，审核中"
    }

    // MARK: - AI Backend
    private func askAI(operation: String, prompt: String, imageData: Data? = nil) async -> String? {
        lastAIErrorMessage = nil

        var body: [String: Any] = [
            "operation": operation,
            "prompt": prompt,
            "schemaVersion": 1
        ]
        if let imageData {
            body["imageBase64"] = imageData.base64EncodedString()
            body["imageMimeType"] = imageMimeType(for: imageData)
        }

        for url in aiBackendURLs {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 18
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)

            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    let message = parseAIError(from: data, response: response)
                    lastAIErrorMessage = message
                    print("AI backend rejected request: \(message)")
                    continue
                }
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let content = json["content"] as? String {
                    return content
                }
                lastAIErrorMessage = "AI 返回内容格式异常"
            } catch {
                lastAIErrorMessage = "网络连接失败"
                print("AI backend error at \(url.host ?? "unknown"): \(error)")
            }
        }
        return nil
    }

    private func parseAIError(from data: Data, response: URLResponse) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? String,
           !error.isEmpty {
            return error
        }

        if let http = response as? HTTPURLResponse {
            return "AI 后端返回错误 \(http.statusCode)"
        }

        return "AI 后端没有响应"
    }

    private func aiUnavailableMessage(fallback: String) -> String {
        if let lastAIErrorMessage, !lastAIErrorMessage.isEmpty {
            return "联网 AI 暂时连不上：\(lastAIErrorMessage)。\(fallback)"
        }
        return "联网 AI 暂时连不上，\(fallback)"
    }

    private func imageMimeType(for data: Data) -> String {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        }
        if data.starts(with: [0x52, 0x49, 0x46, 0x46]) {
            return "image/webp"
        }
        return "image/jpeg"
    }

    private func parseSystem(from json: String) -> NovelSystem? {
        guard let data = cleanedJSON(json).data(using: .utf8),
              let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return NovelSystem(name: d["name"] as? String ?? "未知系统",
                           star: d["starRating"] as? Int ?? 3,
                           type: d["type"] as? String ?? "未知",
                           personality: d["personality"] as? String ?? "神秘",
                           intro: d["intro"] as? String ?? "一个神秘的系统...",
                           icon: d["icon"] as? String ?? "🌟",
                           specialty: d["specialty"] as? String ?? "全能")
    }

    private func parseTask(from json: String, systemName: String) -> SystemTask? {
        guard let data = cleanedJSON(json).data(using: .utf8),
              let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let difficulty = safeDifficulty(d["difficulty"] as? Int)
        let reward = rewardForDifficulty(difficulty)
        let title = sanitizedTaskText(d["title"] as? String)
        let description = sanitizedTaskText(d["description"] as? String)
        guard title.count >= 4, description.count >= 12, title != "日常任务" else { return nil }
        return SystemTask(title: title,
                          desc: description,
                          diff: difficulty,
                          coins: reward.coins,
                          exp: reward.exp,
                          systemName: systemName,
                          deadline: Date().addingTimeInterval(taskDuration(for: difficulty)))
    }

    private func cleanedJSON(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }

    private func fallbackTask(for systemName: String) -> SystemTask {
        let candidates = [
            fallbackTaskCandidate(title: "\(systemName)专属校准", desc: "按当前系统的口吻，选择一件和它专长相关的小事，专注完成并写下结果。", diff: 1, systemName: systemName),
            fallbackTaskCandidate(title: "\(systemName)能量回路", desc: "完成一次十分钟行动，把拖延、学习或整理中的一个现实节点推进到可见状态。", diff: 2, systemName: systemName),
            fallbackTaskCandidate(title: "\(systemName)突破试炼", desc: "挑一个今天最抗拒但有价值的目标，开十五分钟计时，完成第一段推进。", diff: 3, systemName: systemName)
        ]
        return candidates.randomElement()!
    }

    private func finishTaskReview(_ task: SystemTask, proof: String, imageData: Data?, passed: Bool, feedback: String) {
        let previousStatus = userData.tasks.first(where: { $0.id == task.id })?.status

        if let idx = userData.tasks.firstIndex(where: { $0.id == task.id }) {
            userData.tasks[idx].proofText = proof
            userData.tasks[idx].proofImageData = imageData
            userData.tasks[idx].aiFeedback = feedback
            userData.tasks[idx].status = passed ? .completed : .failed
        }

        if passed && previousStatus != .completed {
            userData.coins += task.rewardCoins
            let oldLevel = UserLevel.levelFor(exp: userData.totalExp)
            userData.totalExp += task.rewardExp
            userData.completedTasks += 1
            let lv = UserLevel.levelFor(exp: userData.totalExp)
            if lv.level > oldLevel.level {
                newLevel = lv
                showLevelUp = true
            }
        }

        lastTaskResult = (task, passed, feedback)
        showTaskFeedback = true
        save()
    }

    private var currentRerollCount: Int {
        if userData.lastRerollDate == Self.dateKey(Date()) {
            return userData.rerollCount
        }
        return 0
    }

    private var latestTaskAllowsImmediateClaim: Bool {
        guard let latest = userData.tasks.first else { return false }
        return latest.status == .completed
    }

    private func refreshRerollWindow() {
        if userData.lastRerollDate != Self.dateKey(Date()) {
            userData.rerollCount = 0
            userData.lastRerollDate = Self.dateKey(Date())
        }
    }

    private func expireOverdueTasks() {
        var changed = false
        for index in userData.tasks.indices {
            if userData.tasks[index].deadline == nil,
               (userData.tasks[index].status == .pending || userData.tasks[index].status == .submitted) {
                userData.tasks[index].deadline = userData.tasks[index].createdAt.addingTimeInterval(taskDuration(for: userData.tasks[index].difficulty))
                changed = true
            }
            if isTaskExpired(userData.tasks[index]),
               (userData.tasks[index].status == .pending || userData.tasks[index].status == .submitted) {
                userData.tasks[index].status = .expired
                userData.tasks[index].aiFeedback = "倒计时结束，任务已失效。"
                changed = true
            }
        }
        if changed { save() }
    }

    private func isTaskExpired(_ task: SystemTask) -> Bool {
        guard let deadline = task.deadline else { return false }
        return Date() >= deadline && (task.status == .pending || task.status == .submitted)
    }

    private func taskDuration(for difficulty: Int) -> TimeInterval {
        switch safeDifficulty(difficulty) {
        case 1: return 15 * 60
        case 2: return 30 * 60
        case 3: return 60 * 60
        case 4: return 2 * 60 * 60
        default: return 4 * 60 * 60
        }
    }

    private func fallbackTaskCandidate(title: String, desc: String, diff: Int, systemName: String) -> SystemTask {
        let reward = rewardForDifficulty(diff)
        return SystemTask(title: title, desc: desc, diff: diff, coins: reward.coins, exp: reward.exp, systemName: systemName, deadline: Date().addingTimeInterval(taskDuration(for: diff)))
    }

    private func sanitizedTaskText(_ value: String?) -> String {
        (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分"
        }
        if minutes > 0 {
            return "\(minutes)分\(secs)秒"
        }
        return "\(secs)秒"
    }

    private func safeDifficulty(_ value: Int?) -> Int {
        min(max(value ?? 2, 1), 5)
    }

    private func rewardForDifficulty(_ difficulty: Int) -> (coins: Int, exp: Int) {
        switch safeDifficulty(difficulty) {
        case 1: return (10, 20)
        case 2: return (16, 35)
        case 3: return (24, 55)
        case 4: return (34, 80)
        default: return (46, 110)
        }
    }

    private func consumeReviewQuota() -> Bool {
        let today = Self.dateKey(Date())
        let defaults = UserDefaults.standard
        if defaults.string(forKey: reviewQuotaDateKey) != today {
            defaults.set(today, forKey: reviewQuotaDateKey)
            defaults.set(0, forKey: reviewQuotaCountKey)
        }

        let count = defaults.integer(forKey: reviewQuotaCountKey)
        guard count < maxDailyReviews else { return false }
        defaults.set(count + 1, forKey: reviewQuotaCountKey)
        return true
    }

    private func isAllowedUserText(_ text: String) -> Bool {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
        let blocked = ["傻逼","他妈的","操你妈","fuck","shit","习近平","法轮功","六四","台独","赌博","毒品"]
        return !blocked.contains { normalized.contains($0.lowercased()) }
    }

    private func notify(_ message: String) {
        appMessage = message
        showAppMessage = true
    }

    private func finishHallReview(_ hallTask: SharedTask, passed: Bool, feedback: String) {
        let resultTask = SystemTask(
            title: hallTask.title,
            desc: hallTask.description,
            diff: hallTask.difficulty,
            coins: hallTask.rewardCoins,
            exp: hallTask.rewardExp,
            systemName: hallTask.systemName
        )

        guard passed else {
            lastTaskResult = (resultTask, false, feedback)
            showTaskFeedback = true
            save()
            return
        }

        let oldLevel = UserLevel.levelFor(exp: userData.totalExp)
        userData.coins += hallTask.rewardCoins
        userData.totalExp += hallTask.rewardExp
        userData.completedHallTaskCount += 1
        userData.completedTasks += 1
        userData.acceptedHallTask = nil

        if let idx = hallTasks.firstIndex(where: { $0.id == hallTask.id }) {
            hallTasks[idx].completed = true
            hallTasks[idx].acceptedBy = hallTasks[idx].acceptedBy ?? userData.systemName
        }

        let lv = UserLevel.levelFor(exp: userData.totalExp)
        if lv.level > oldLevel.level {
            newLevel = lv
            showLevelUp = true
        }

        lastTaskResult = (resultTask, true, feedback)
        showTaskFeedback = true
        save()
        saveHall()
    }

    // MARK: - Persistence
    func save() {
        if let d = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: key),
           let u = try? JSONDecoder().decode(SystemUserData.self, from: d) {
            userData = u
        }
    }

    private func saveHall() {
        if let d = try? JSONEncoder().encode(hallTasks) {
            UserDefaults.standard.set(d, forKey: hallKey)
        }
    }

    private func loadHall() {
        if let d = UserDefaults.standard.data(forKey: hallKey),
           let tasks = try? JSONDecoder().decode([SharedTask].self, from: d) {
            hallTasks = tasks
        }
        // 初始化一些模拟大厅任务
        if hallTasks.isEmpty {
            hallTasks = [
                SharedTask(id: UUID(), originalTaskID: UUID(), publisherName: "万界签到系统",
                    title: "晨跑5公里", description: "清晨起床，绕小区跑5公里，感受灵力在体内流转！",
                    difficulty: 2, rewardCoins: 15, rewardExp: 30, systemName: "万界签到系统", createdAt: Date()),
                SharedTask(id: UUID(), originalTaskID: UUID(), publisherName: "美食修仙系统",
                    title: "做一道创意料理", description: "用冰箱里任意三种食材，做一道从未尝过的创意菜！",
                    difficulty: 1, rewardCoins: 10, rewardExp: 20, systemName: "美食修仙系统", createdAt: Date()),
                SharedTask(id: UUID(), originalTaskID: UUID(), publisherName: "学霸无敌系统",
                    title: "读完一本书的一个章节", description: "静下心来，读完一本书的至少一个完整章节并做笔记。",
                    difficulty: 2, rewardCoins: 12, rewardExp: 25, systemName: "学霸无敌系统", createdAt: Date()),
                SharedTask(id: UUID(), originalTaskID: UUID(), publisherName: "社恐逆袭系统",
                    title: "主动和陌生人说一句话", description: "在咖啡店或公交上，主动开口和陌生人说一句话。",
                    difficulty: 3, rewardCoins: 20, rewardExp: 40, systemName: "社恐逆袭系统", createdAt: Date()),
            ]
            saveHall()
        }
    }

    static func dateKey(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: d)
    }
}
