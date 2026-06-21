import SwiftUI

// MARK: - Panel Navigation
enum Panel: Equatable {
    case home, seeds, memory, rhythm, insights
}

// MARK: - Seed (small task)
struct Seed: Identifiable {
    let id: UUID
    var label: String
    var done: Bool

    init(id: UUID = UUID(), label: String, done: Bool = false) {
        self.id = id
        self.label = label
        self.done = done
    }
}

// MARK: - Memory Bubble
struct MemoryItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let size: CGFloat
    let xFraction: CGFloat
    let yFraction: CGFloat
    let animDelay: Double

    init(id: UUID = UUID(), title: String, subtitle: String,
         size: CGFloat, xFraction: CGFloat, yFraction: CGFloat, animDelay: Double = 0) {
        self.id = id; self.title = title; self.subtitle = subtitle
        self.size = size; self.xFraction = xFraction; self.yFraction = yFraction
        self.animDelay = animDelay
    }
}

// MARK: - Rhythm Block
struct RhythmBlock: Identifiable {
    let id: UUID
    let tag: String
    let title: String
    let color: Color

    init(id: UUID = UUID(), tag: String, title: String, color: Color) {
        self.id = id; self.tag = tag; self.title = title; self.color = color
    }
}

// MARK: - Insight Answer
struct InsightAnswer: Identifiable {
    let id: UUID
    let label: String
    let reply: String       // Immediate empathetic reply
    let havenPlan: String   // What Haven will do based on this answer

    init(id: UUID = UUID(), label: String, reply: String, havenPlan: String) {
        self.id = id; self.label = label; self.reply = reply; self.havenPlan = havenPlan
    }
}

// MARK: - Insight Item
struct InsightItem: Identifiable {
    let id: UUID
    let question: String    // The observation Haven noticed
    let reason: String      // Why this insight appeared — what the user did
    let answers: [InsightAnswer]

    init(id: UUID = UUID(), question: String, reason: String, answers: [InsightAnswer]) {
        self.id = id; self.question = question; self.reason = reason; self.answers = answers
    }
}

// MARK: - Insight interaction state
enum InsightState: Equatable {
    case unanswered
    case pendingConfirm(answerId: UUID)
    case confirmed
}

// MARK: - Color helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}
