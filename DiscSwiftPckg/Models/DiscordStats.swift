import Foundation

/// Comprehensive Discord statistics from data package
struct DiscordStats {
    // User info
    var user: DiscordUser?
    var connections: [(type: String, name: String)] = []
    var friendCount: Int = 0
    var blockedCount: Int = 0
    var noteCount: Int = 0
    var recentAvatars: [URL] = []
    
    
    // Message stats
    var messageCount: Int = 0
    var wordCount: Int = 0
    var characterCount: Int = 0
    var mentionCount: Int = 0
    var emoteCount: Int = 0
    var emojiCount: Int = 0
    var filesUploaded: Int = 0
    
    // Activity by time
    var messagesByHour: [Int] = Array(repeating: 0, count: 24)
    var messagesByDay: [Int] = Array(repeating: 0, count: 7) // Mon-Sun
    var messagesByYear: [Int: Int] = [:]
    
    // Top lists
    var topWords: [(word: String, count: Int)] = []
    var topCustomEmojis: [(name: String, id: String, count: Int, imageURL: String)] = []
    var topDMs: [(name: String, messageCount: Int)] = []
    var topServers: [(name: String, messageCount: Int)] = []
    var topChannels: [(name: String, serverName: String, messageCount: Int)] = []
    
    // DM stats
    var dmConversations: Int = 0
    var dmMessages: Int = 0
    var groupDMCount: Int = 0
    
    // Server stats
    var serverCount: Int = 0
    var serverNames: [String] = []
    var serverChannelCount: Int = 0
    var serverMessages: Int = 0
    var mutedServerCount: Int = 0
    
    // Events/Analytics
    var appOpenedCount: Int = 0
    var voiceChannelJoins: Int = 0
    var callsJoined: Int = 0
    var reactionsAdded: Int = 0
    var reactionsRemoved: Int = 0
    var messagesEdited: Int = 0
    var messagesDeleted: Int = 0
    var slashCommandsUsed: Int = 0
    var notificationsClicked: Int = 0
    var invitesSent: Int = 0
    var giftsSent: Int = 0
    var searchesStarted: Int = 0
    var appCrashes: Int = 0
    
    // Payments
    var totalSpent: [String: Double] = [:]
    var paymentCount: Int = 0
    
    // Computed properties
    var mostActiveHour: Int {
        messagesByHour.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }
    
    var mostActiveDay: String {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let idx = messagesByDay.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        return days[idx]
    }
    
    var mostActiveYear: Int {
        messagesByYear.max(by: { $0.value < $1.value })?.key ?? 2024
    }
    
    var accountAgeDays: Int {
        user?.accountAgeDays ?? 0
    }
    
    var messagesPerDay: Double {
        guard accountAgeDays > 0 else { return 0 }
        return Double(messageCount) / Double(accountAgeDays)
    }
    
    var formattedTotalSpent: String {
        if totalSpent.isEmpty { return "$0.00" }
        return totalSpent.map { "\($0.key.uppercased()) \(String(format: "%.2f", $0.value))" }.joined(separator: ", ")
    }
    
    // Avatar URL
    var avatarURL: URL? {
        guard let user = user,
              let avatarHash = user.avatarHash,
              !avatarHash.isEmpty else { return nil }
        let ext = avatarHash.hasPrefix("a_") ? "gif" : "png"
        return URL(string: "https://cdn.discordapp.com/avatars/\(user.id)/\(avatarHash).\(ext)?size=128")
    }
}
