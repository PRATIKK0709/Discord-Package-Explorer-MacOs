import Foundation

struct DiscordTicket: Codable, Identifiable {
    let ticketId: Int
    let status: String
    let subject: String?
    let createdAt: String
    let comments: [TicketComment]
    
    var id: String { String(ticketId) }
    
    enum CodingKeys: String, CodingKey {
        case ticketId = "ticket_id"
        case status
        case subject
        case createdAt = "created_at"
        case comments
    }
    
    // Helper to sort messages
    var sortedMessages: [TicketComment] {
        comments.sorted { $0.createdAt < $1.createdAt }
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

struct TicketComment: Codable, Identifiable {
    let author: String
    let comment: String
    let createdAt: String
    
    var id: String { createdAt }
    
    enum CodingKeys: String, CodingKey {
        case author
        case comment
        case createdAt = "created_at"
    }
}
