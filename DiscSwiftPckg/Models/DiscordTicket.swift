import Foundation

struct DiscordTicket: Codable, Identifiable {
    let id: String
    let status: String
    let subject: String?
    let createdAt: String
    let messages: [TicketMessage]
    
    enum CodingKeys: String, CodingKey {
        case id, status, subject, messages
        case createdAt = "created_at"
    }
    
    // Helper to sort messages
    var sortedMessages: [TicketMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: createdAt) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return createdAt
    }
}

struct TicketMessage: Codable, Identifiable {
    var id: String { timestamp } // No ID in some exports, use timestamp
    let author: TicketAuthor
    let content: String
    let timestamp: String
    let attachments: [String]?
    
    struct TicketAuthor: Codable {
        let username: String
        let discriminator: String?
        let avatar: String?
        let bot: Bool?
    }
}
