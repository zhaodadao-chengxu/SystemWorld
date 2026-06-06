import Foundation
import SwiftUI

// MARK: - 系统

struct NovelSystem: Identifiable, Codable, Equatable {
    static func == (lhs: NovelSystem, rhs: NovelSystem) -> Bool { lhs.id == rhs.id }
    let id: UUID
    let name: String
    let starRating: Int       // 1-5
    let type: String
    let personality: String
    let intro: String
    let icon: String
    let specialty: String

    init(id: UUID = UUID(), name: String, star: Int, type: String, personality: String, intro: String, icon: String, specialty: String) {
        self.id = id; self.name = name; self.starRating = star
        self.type = type; self.personality = personality; self.intro = intro
        self.icon = icon; self.specialty = specialty
    }
}

// MARK: - 系统任务

struct SystemTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let difficulty: Int       // 1-5
    let rewardCoins: Int
    let rewardExp: Int
    var status: TaskStatus
    let systemName: String
    let createdAt: Date
    let deadline: Date?
    var proofText: String?
    var proofImageData: Data?  // 图片证明
    var aiFeedback: String?
    var isPublishedToHall: Bool = false  // 是否发布到大厅

    enum TaskStatus: String, Codable { case pending, submitted, completed, failed }

    init(id: UUID = UUID(), title: String, desc: String, diff: Int, coins: Int, exp: Int, systemName: String, deadline: Date? = nil) {
        self.id = id; self.title = title; self.description = desc; self.difficulty = diff
        self.rewardCoins = coins; self.rewardExp = exp; self.systemName = systemName
        self.status = .pending; self.createdAt = Date(); self.deadline = deadline
    }
}

// MARK: - 大厅共享任务

struct SharedTask: Identifiable, Codable {
    let id: UUID
    let originalTaskID: UUID
    let publisherName: String
    let title: String
    let description: String
    let difficulty: Int
    let rewardCoins: Int
    let rewardExp: Int
    let systemName: String
    let createdAt: Date
    var acceptedBy: String?
    var completed: Bool = false

    init(task: SystemTask, publisherName: String) {
        self.id = UUID()
        self.originalTaskID = task.id
        self.publisherName = publisherName
        self.title = task.title
        self.description = task.description
        self.difficulty = task.difficulty
        self.rewardCoins = task.rewardCoins / 2
        self.rewardExp = task.rewardExp / 2
        self.systemName = task.systemName
        self.createdAt = Date()
    }

    init(id: UUID = UUID(), originalTaskID: UUID, publisherName: String, title: String, description: String, difficulty: Int, rewardCoins: Int, rewardExp: Int, systemName: String, createdAt: Date, acceptedBy: String? = nil, completed: Bool = false) {
        self.id = id
        self.originalTaskID = originalTaskID
        self.publisherName = publisherName
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.rewardCoins = rewardCoins
        self.rewardExp = rewardExp
        self.systemName = systemName
        self.createdAt = createdAt
        self.acceptedBy = acceptedBy
        self.completed = completed
    }
}

// MARK: - 用户等级与超能力

struct UserLevel: Identifiable {
    var id: Int { level }
    let level: Int; let name: String; let expRequired: Int
    let fakePower: String; let powerDesc: String

    static let all: [UserLevel] = [
        UserLevel(level:0, name:"凡人",       expRequired:0,      fakePower:"无",              powerDesc:"诸天万界时代还未降临..."),
        UserLevel(level:1, name:"觉醒者",     expRequired:100,    fakePower:"微弱灵力",          powerDesc:"能感知到天地间飘荡的灵气粒子"),
        UserLevel(level:2, name:"练气士",     expRequired:500,    fakePower:"灵气操控",          powerDesc:"可引导灵气淬炼肉身，一拳碎木"),
        UserLevel(level:3, name:"筑基修士",   expRequired:2000,   fakePower:"神识初开",          powerDesc:"神念外放十米，洞悉周遭一切"),
        UserLevel(level:4, name:"金丹真人",   expRequired:8000,   fakePower:"丹火护体",          powerDesc:"体内金丹运转，水火不侵、百毒不惧"),
        UserLevel(level:5, name:"元婴老怪",   expRequired:30000,  fakePower:"元婴出窍",          powerDesc:"神魂离体遨游，瞬息千里之外"),
        UserLevel(level:6, name:"化神大能",   expRequired:100000, fakePower:"法则之力",          powerDesc:"触摸天地法则，言出法随、一念花开"),
        UserLevel(level:7, name:"渡劫仙尊",   expRequired:500000, fakePower:"天劫掌控",          powerDesc:"引动九天神雷，渡劫飞升指日可待"),
        UserLevel(level:8, name:"大罗金仙",   expRequired:2000000,fakePower:"时空法则",          powerDesc:"穿梭诸天万界，时间空间皆为玩物"),
        UserLevel(level:9, name:"混元道祖",   expRequired:10000000,fakePower:"创世之力",         powerDesc:"一念创世、一念灭世，与天道齐平"),
    ]

    static func levelFor(exp: Int) -> UserLevel {
        all.last(where: { exp >= $0.expRequired }) ?? all[0]
    }
}

// MARK: - 用户数据

struct SystemUserData: Codable {
    var currentSystem: NovelSystem?
    var systemHistory: [NovelSystem] = []
    var tasks: [SystemTask] = []
    var completedTasks: Int = 0
    var totalExp: Int = 0
    var coins: Int = 0
    var systemName: String = "未绑定"
    var lastTaskDate: String = ""
    var rerollCount: Int = 0
    var interactionLog: [String] = []

    // 大厅相关
    var sharedTasks: [SharedTask] = []        // 我发布到大厅的任务
    var acceptedHallTask: SharedTask? = nil    // 我从大厅接的任务
    var completedHallTaskCount: Int = 0

    // 分享相关
    var lastShareDate: String = ""
    var shareStreak: Int = 0
}
