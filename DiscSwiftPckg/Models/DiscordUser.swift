import Foundation

/// Discord user profile from Account/user.json
struct DiscordUser: Codable {
    let id: String
    let username: String
    let discriminator: String?
    let globalName: String?
    let email: String?
    let phone: String?
    let verified: Bool?
    let mfaEnabled: Bool?
    let premiumType: Int?
    let flags: Int?
    let avatarHash: String?
    let payments: [DiscordPayment]?
    
    enum CodingKeys: String, CodingKey {
        case id, username, discriminator, email, phone, verified, payments, flags
        case globalName = "global_name"
        case mfaEnabled = "mfa_enabled"
        case premiumType = "premium_type"
        case avatarHash = "avatar_hash"
    }
    
    /// Account creation date derived from Discord snowflake ID
    var createdAt: Date {
        let snowflake = UInt64(id) ?? 0
        let timestamp = (snowflake >> 22) + 1420070400000
        return Date(timeIntervalSince1970: Double(timestamp) / 1000)
    }
    
    /// Account age in days
    var accountAgeDays: Int {
        Int(Date().timeIntervalSince(createdAt) / 86400)
    }
    
    /// Nitro status based on premium_type
    var nitroStatus: String {
        switch premiumType {
        case 1: return "Nitro Classic"
        case 2: return "Nitro"
        case 3: return "Nitro Basic"
        default: return "None"
        }
    }
    
    /// Masked email for display
    var maskedEmail: String? {
        guard let email = email, let atIndex = email.firstIndex(of: "@") else { return nil }
        let prefix = email.prefix(2)
        let domain = email[atIndex...]
        return "\(prefix)***\(domain)"
    }
}

/// Payment record from user.json
struct DiscordPayment: Codable {
    let id: String?
    let amount: Int?
    let currency: String?
    let status: Int?
    let description: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, currency, status, description
        case createdAt = "created_at"
    }
    
    /// Formatted amount
    var formattedAmount: String {
        guard let amount = amount, let currency = currency else { return "N/A" }
        return "\(currency.uppercased()) \(Double(amount) / 100.0)"
    }
    
    /// Is confirmed payment
    var isConfirmed: Bool {
        status == 1
    }
}

/// Bot application from Account/applications/
struct DiscordBot: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String?
    let botToken: String?
    let publicKey: String?
    
    // Local image URL for UI
    var localIconURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon
        case botToken = "bot_token"
        case publicKey = "public_key"
    }
}
