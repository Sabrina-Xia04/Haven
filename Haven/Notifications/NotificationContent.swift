import Foundation

// MARK: - Notification Categories
enum HavenNotificationCategory: String {
    case checkIn      = "HAVEN_CHECKIN"
    case gentleNudge  = "HAVEN_NUDGE"
    case futureself   = "HAVEN_FUTURE"
    case returnWelcome = "HAVEN_RETURN"
}

// MARK: - All Haven notification messages
struct HavenMessages {

    // MARK: Check-in (asks how user feels — has reply actions)
    static let checkIns: [(title: String, body: String)] = [
        ("Just checking in 🌊",         "How does today feel so far?"),
        ("Haven is here",               "How are you holding up right now?"),
        ("A quiet moment",              "How's your energy today?"),
        ("I noticed it's been a while", "Are you doing okay?"),
        ("Evening check-in",            "How was today for you?"),
        ("Good morning 🌸",             "How are you feeling as the day begins?"),
    ]

    // MARK: Gentle nudges (seeds / tasks)
    static let nudges: [(title: String, body: String)] = [
        ("A small thing",               "Your seeds are waiting — even one counts today."),
        ("No pressure",                 "Just a gentle nudge. One small step is enough."),
        ("Future you says hi",          "Would finishing one small thing feel good right now?"),
        ("I remember",                  "Last time, starting small helped. Want to try again?"),
        ("One seed 🌱",                 "You don't have to do everything. Just one thing."),
    ]

    // MARK: Future self
    static let futureself: [(title: String, body: String)] = [
        ("From your future self",       "Would future you appreciate a small break right now?"),
        ("A note from tomorrow",        "I remember similar nights. Rest is not wasted time."),
        ("Future you is watching",      "Saving a little energy tonight might matter tomorrow."),
        ("Haven gentle reminder",       "What would you thank yourself for doing right now?"),
        ("Protect tomorrow",            "You've done enough today. Would resting feel okay?"),
    ]

    // MARK: Return welcome (if user hasn't opened app in a while)
    static let returnWelcome: [(title: String, body: String)] = [
        ("Welcome back 🌊",             "It's okay to be away. I'm still here."),
        ("Haven missed you",            "No explanation needed. Just glad you're here."),
        ("I'm still here",              "Whenever you're ready, I'll be waiting."),
        ("It's okay",                   "You don't have to catch up on anything. Just breathe."),
    ]

    // MARK: Pattern-aware (time-of-day)
    static func patternMessage(hour: Int) -> (title: String, body: String) {
        switch hour {
        case 7..<10:
            return ("Good morning 🌸", "Your morning window is open. Even a slow start is a start.")
        case 12..<14:
            return ("Midday check-in", "How's your energy right now? Afternoons can be your clearest window.")
        case 15..<17:
            return ("Afternoon nudge", "I noticed afternoons often work well for you. Anything small to try?")
        case 20..<23:
            return ("Evening arrived", "Today is done. Would resting — or just breathing — feel okay?")
        default:
            return ("Haven is here 🌊", "Just checking in. How are you holding up?")
        }
    }
}

// MARK: - Notification Action IDs
enum CheckInAction: String {
    case feelingOkay      = "FEELING_OKAY"
    case feelingHeavy     = "FEELING_HEAVY"
    case feelingStruggle  = "FEELING_STRUGGLE"
    case remindLater      = "REMIND_LATER"
}
