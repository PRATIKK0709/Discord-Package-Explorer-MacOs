import Foundation

/// Individual message from messages.json
struct DiscordMessage: Codable {
    let id: String
    let timestamp: String
    let contents: String?
    let attachments: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case timestamp = "Timestamp"
        case contents = "Contents"
        case attachments = "Attachments"
    }
    
    /// Parse timestamp to Date
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp) ?? ISO8601DateFormatter().date(from: timestamp)
    }
    
    /// Hour of day (0-23) for activity chart
    var hourOfDay: Int {
        guard let date = date else { return 0 }
        return Calendar.current.component(.hour, from: date)
    }
    
    /// Word count
    var wordCount: Int {
        contents?.split(separator: " ").count ?? 0
    }
    
    /// Character count
    var characterCount: Int {
        contents?.count ?? 0
    }
}

/// Channel metadata from channel.json
struct DiscordChannel: Codable {
    let id: String
    let type: Int?
    let name: String?
    let recipients: [String]?
    let guild: DiscordGuildInfo?
    
    /// Is this a DM channel
    var isDM: Bool {
        type == 1 || (recipients != nil && guild == nil)
    }
    
    /// Is this a group DM
    var isGroupDM: Bool {
        type == 3
    }
    
    /// Display name for the channel
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if isDM {
            return "Direct Message"
        }
        return "Channel \(id.suffix(4))"
    }
}

/// Minimal guild info embedded in channel.json
struct DiscordGuildInfo: Codable {
    let id: String?
    let name: String?
}

/// Parsed channel with messages
struct ParsedChannel {
    let channel: DiscordChannel
    let messages: [DiscordMessage]
    let indexName: String?
    
    var messageCount: Int { messages.count }
    var characterCount: Int { messages.reduce(0) { $0 + $1.characterCount } }
    
    var displayName: String {
        indexName ?? channel.displayName
    }
}
