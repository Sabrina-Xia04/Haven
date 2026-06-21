import SwiftUI

class HavenViewModel: ObservableObject {

    // MARK: - Navigation
    @Published var currentPanel: Panel = .home

    // MARK: - Home state
    @Published var speechText: String? = nil
    @Published var memoryText: String? = nil
    @Published var isReturning: Bool = false

    // MARK: - Seeds
    @Published var seeds: [Seed] = [] {
        didSet { saveSeeds() }
    }

    // MARK: - Memory Ocean
    @Published var memoryItems: [MemoryItem] = []

    // MARK: - Rhythm (time-aware)
    var rhythmBlocks: [RhythmBlock] {
        let hour = Calendar.current.component(.hour, from: Date())
        return [
            RhythmBlock(
                tag: "Morning",
                title: hour < 12 ? "Start slow — that's okay" : "Morning has passed",
                color: Color(hex: "f5dfc4"),
                isCurrent: hour >= 5 && hour < 12
            ),
            RhythmBlock(
                tag: "Afternoon",
                title: "Your clearest window",
                color: Color(hex: "cbe9d6"),
                isCurrent: hour >= 12 && hour < 17
            ),
            RhythmBlock(
                tag: "Evening",
                title: hour >= 21 ? "Rest is okay now" : "Protect your rest",
                color: Color(hex: "cfc4e8"),
                isCurrent: hour >= 17
            ),
        ]
    }

    // MARK: - Insights
    @Published var insightState: InsightState = .unanswered
    @Published var currentInsightIndex: Int = 0

    let insights: [InsightItem] = [
        InsightItem(
            question: "Your focus seems to break mainly before tasks that someone else will judge.",
            reason: "You've left 3 peer-review Seeds untouched for 4 days while completing solo tasks quickly. The pattern repeats across two separate weeks.",
            answers: [
                InsightAnswer(label: "Yes",
                    reply: "That makes sense. Judgment from others is a real weight — not imaginary.",
                    havenPlan: "Before high-stakes tasks, I'll suggest a small warmup seed first. I'll also remind you that imperfection is the whole point of a first draft."),
                InsightAnswer(label: "Sort of",
                    reply: "Partially counts. I'll keep watching for when it's clearest.",
                    havenPlan: "I'll track which Seeds stay stuck the longest and look for patterns around audience or visibility. Check back in a few days."),
                InsightAnswer(label: "Not really",
                    reply: "Good to know — I might be wrong about this one.",
                    havenPlan: "I'll set this aside and look for a different pattern. Nothing changes on my end until I'm more confident."),
            ]
        ),
        InsightItem(
            question: "You tend to skip meals on the same days you mark the most Seeds done.",
            reason: "Your Seeds log shows your most productive streaks often have no food-related seeds completed — and the busiest days rarely have any meal entries at all.",
            answers: [
                InsightAnswer(label: "Yes",
                    reply: "You already know, which means part of you is watching out for yourself.",
                    havenPlan: "On days when you're in a focused streak, I'll quietly add an 'Eat something' seed — nothing prescriptive, just a soft signal."),
                InsightAnswer(label: "Sometimes",
                    reply: "Sometimes is enough to be worth noticing.",
                    havenPlan: "I'll only add a gentle food reminder on the heaviest-looking days. Easy to ignore if it doesn't fit."),
                InsightAnswer(label: "Not really",
                    reply: "Okay — maybe it's a coincidence in the data.",
                    havenPlan: "I'll stop tracking this pattern for now. If it shows up differently later, I'll mention it again."),
            ]
        ),
        InsightItem(
            question: "Your evenings tend to feel heavier than your mornings — even on good days.",
            reason: "The times you open Haven shift later and later during stressful weeks. Your rhythm check-ins also suggest mornings are when you feel most capable.",
            answers: [
                InsightAnswer(label: "Yes",
                    reply: "A lot of people carry the day's weight into the evening. It's not a flaw.",
                    havenPlan: "I'll send a soft wind-down note around 8pm on days that look heavy — not a demand, just a signal that the day is allowed to end."),
                InsightAnswer(label: "Sort of",
                    reply: "Even partially true is worth paying attention to.",
                    havenPlan: "I'll watch evening vs morning patterns a bit longer before adjusting anything. No changes yet."),
                InsightAnswer(label: "Not really",
                    reply: "Good. Maybe your evenings are more protected than I thought.",
                    havenPlan: "I'll revisit this one later. Nothing changes for now."),
            ]
        ),
        InsightItem(
            question: "Rest doesn't seem to feel like rest when it's unplanned.",
            reason: "You've returned to Haven late at night several times after marking nothing done. Those days usually follow days with no scheduled breaks — rest happened, but without intention.",
            answers: [
                InsightAnswer(label: "That's it",
                    reply: "Unstructured rest often feels like avoidance instead. That distinction matters.",
                    havenPlan: "I'll suggest one small, named rest seed per day — something specific like 'sit outside for 10 minutes' — so rest has a shape and feels chosen."),
                InsightAnswer(label: "Maybe",
                    reply: "Worth holding loosely. You might just need more data points.",
                    havenPlan: "I'll add a gentle rest seed once or twice a week and see if it helps. You can always skip it."),
                InsightAnswer(label: "Not for me",
                    reply: "Fair — unstructured rest might actually be what works for you.",
                    havenPlan: "I'll leave your rest alone. Noted that structure here doesn't help."),
            ]
        ),
        InsightItem(
            question: "You're kinder about hard days when you name them out loud.",
            reason: "Your long-press memory requests tend to happen after difficult days — and the messages you send yourself afterward are noticeably gentler than when you say nothing.",
            answers: [
                InsightAnswer(label: "Yes",
                    reply: "Naming something takes away a little of its power. You already know how to do this.",
                    havenPlan: "At the end of days that look hard, I'll gently invite you to name one difficult thing — not to solve it, just to put it somewhere outside of you."),
                InsightAnswer(label: "Sometimes",
                    reply: "Even sometimes is worth building on.",
                    havenPlan: "I'll make the invitation occasional, not routine — only when it looks like you might actually want it."),
                InsightAnswer(label: "Not really",
                    reply: "That's okay. Silence can also be a form of processing.",
                    havenPlan: "I'll stop prompting reflection for now. You can always long-press to share something when you're ready."),
            ]
        ),
    ]

    var currentInsight: InsightItem { insights[currentInsightIndex % insights.count] }

    // MARK: - Init
    init() {
        seeds = Self.loadSeeds()
        memoryItems = Self.loadMemories()
        checkDailyReset()
    }

    // MARK: - Insight actions
    func selectAnswer(_ answer: InsightAnswer) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            insightState = .pendingConfirm(answerId: answer.id)
        }
    }

    func confirmInsight() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            insightState = .confirmed
        }
    }

    func backToAnswer() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            insightState = .unanswered
        }
    }

    func advanceInsight() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentInsightIndex += 1
            insightState = .unanswered
        }
    }

    // MARK: - Speeches / Memories cycling
    private let speeches = [
        "I'm here.",
        "Good to see you.",
        "You don't have to explain anything.",
        "Welcome back.",
        "Let's start small.",
    ]
    private let memoryQuotes = [
        "I remember. Last finals week looked similar.",
        "Evening walks helped before.",
        "You recovered before.",
        "Afternoons usually work better for you.",
    ]
    private var speechIndex = 0
    private var memoryIndex = 0

    // MARK: - Jellyfish tap
    func jellyfishTapped() {
        speechText = speeches[speechIndex % speeches.count]
        speechIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.speechText = nil }
        }
    }

    // MARK: - Jellyfish long press
    func jellyfishLongPressed() {
        memoryText = memoryQuotes[memoryIndex % memoryQuotes.count]
        memoryIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.memoryText = nil }
        }
    }

    // MARK: - Returning user toggle
    func toggleReturning() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isReturning.toggle()
        }
    }

    // MARK: - Seed actions
    func toggleSeed(_ seed: Seed) {
        if let idx = seeds.firstIndex(where: { $0.id == seed.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                seeds[idx].done.toggle()
            }
        }
    }

    func deleteSeed(_ seed: Seed) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            seeds.removeAll { $0.id == seed.id }
        }
    }

    // MARK: - Navigation helpers
    func navigateTo(_ panel: Panel) {
        currentPanel = panel
    }

    // MARK: - Memory actions
    func addMemory(title: String, subtitle: String = "") {
        let item = MemoryItem.make(title: title, subtitle: subtitle)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            memoryItems.append(item)
        }
        saveMemories()
    }

    // MARK: - Daily reset
    private func checkDailyReset() {
        let today = Seed.today()
        let lastReset = UserDefaults.standard.string(forKey: "haven_last_reset") ?? ""
        guard today != lastReset else { return }
        // New day: reset all done seeds
        for i in seeds.indices { seeds[i].done = false }
        UserDefaults.standard.set(today, forKey: "haven_last_reset")
    }

    // MARK: - Persistence: Seeds
    private static let seedsKey = "haven_seeds_v2"

    private static func loadSeeds() -> [Seed] {
        guard let data = UserDefaults.standard.data(forKey: seedsKey),
              let decoded = try? JSONDecoder().decode([Seed].self, from: data)
        else {
            return []    // fresh install → empty list
        }
        return decoded
    }

    private func saveSeeds() {
        let data = try? JSONEncoder().encode(seeds)
        UserDefaults.standard.set(data, forKey: Self.seedsKey)
    }

    // MARK: - Persistence: Memories
    private static let memoriesKey = "haven_memories_v1"

    private static func loadMemories() -> [MemoryItem] {
        guard let data = UserDefaults.standard.data(forKey: memoriesKey),
              let decoded = try? JSONDecoder().decode([MemoryItem].self, from: data)
        else { return [] }
        return decoded
    }

    private func saveMemories() {
        let data = try? JSONEncoder().encode(memoryItems)
        UserDefaults.standard.set(data, forKey: Self.memoriesKey)
    }
}
