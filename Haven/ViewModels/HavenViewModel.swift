import SwiftUI

class HavenViewModel: ObservableObject {

    // MARK: - Navigation
    @Published var currentPanel: Panel = .home

    // MARK: - Home state
    @Published var speechText: String? = nil
    @Published var memoryText: String? = nil
    @Published var isReturning: Bool = false

    // MARK: - Seeds
    @Published var seeds: [Seed] = [
        Seed(label: "Reply to Professor"),
        Seed(label: "Continue Research Proposal"),
        Seed(label: "Take a Walk"),
        Seed(label: "Eat Something Warm"),
    ]

    // MARK: - Memory Ocean
    let memoryItems: [MemoryItem] = [
        MemoryItem(title: "Finals Week 2025",      subtitle: "Evening walks helped.\nYou recovered.",        size: 148, xFraction: 0.22, yFraction: 0.30, animDelay: 0.0),
        MemoryItem(title: "Medication Adjustment", subtitle: "Afternoons worked better.",                     size: 158, xFraction: 0.68, yFraction: 0.42, animDelay: 1.2),
        MemoryItem(title: "Hackathon Weekend",     subtitle: "Music helped.",                                 size: 138, xFraction: 0.26, yFraction: 0.62, animDelay: 2.1),
        MemoryItem(title: "Hard Week",             subtitle: "Smaller goals helped.",                         size: 148, xFraction: 0.68, yFraction: 0.72, animDelay: 0.7),
    ]

    // MARK: - Rhythm
    let rhythmBlocks: [RhythmBlock] = [
        RhythmBlock(tag: "Morning", title: "Start slow — that's okay", color: Color(hex: "f5dfc4")),
        RhythmBlock(tag: "Afternoon", title: "Your clearest window",   color: Color(hex: "cbe9d6")),
        RhythmBlock(tag: "Evening",  title: "Protect your rest",       color: Color(hex: "cfc4e8")),
    ]

    // MARK: - Insights
    @Published var insightAnswered: Bool = false
    @Published var insightReply: String = ""
    let insightQuestion = "Your focus seems to break mainly before tasks that someone else will judge."
    let insightAnswers: [InsightAnswer] = [
        InsightAnswer(label: "Yes",   reply: "That makes sense. We can work with this."),
        InsightAnswer(label: "Sort of", reply: "Noted. I'll keep watching."),
        InsightAnswer(label: "Not really", reply: "Good to know — I might be wrong."),
    ]

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

    // MARK: - Seed toggle
    func toggleSeed(_ seed: Seed) {
        if let idx = seeds.firstIndex(where: { $0.id == seed.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                seeds[idx].done.toggle()
            }
        }
    }

    // MARK: - Insight answer
    func answerInsight(_ answer: InsightAnswer) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            insightReply = answer.reply
            insightAnswered = true
        }
    }

    // MARK: - Navigation helpers
    func navigateTo(_ panel: Panel) {
        currentPanel = panel
    }
}
