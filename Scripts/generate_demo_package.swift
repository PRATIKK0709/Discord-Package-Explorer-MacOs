#!/usr/bin/env swift

import Foundation

let fileManager = FileManager.default
let repository = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
let output = repository.appendingPathComponent("demo-package", isDirectory: true)
let privatePackage = repository.appendingPathComponent("package-2", isDirectory: true)

// The output is fully generated, so replacing it makes this script safe to rerun.
if fileManager.fileExists(atPath: output.path) {
    try fileManager.removeItem(at: output)
}

func createDirectory(_ relativePath: String) throws {
    try fileManager.createDirectory(
        at: output.appendingPathComponent(relativePath, isDirectory: true),
        withIntermediateDirectories: true
    )
}

func writeJSON(_ object: Any, to relativePath: String) throws {
    let url = output.appendingPathComponent(relativePath)
    try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    try data.write(to: url, options: .atomic)
}

func copyShowcaseImage(to relativePath: String) throws {
    let source = repository.appendingPathComponent("DiscSwiftPckg/Assets.xcassets/AppIcon.appiconset/icon_256x256.png")
    let destination = output.appendingPathComponent(relativePath)
    try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try fileManager.copyItem(at: source, to: destination)
}

func billingExport(section: String, records: [[String: Any]]) -> [String: Any] {
    [
        "section": section,
        "generated_at": "2026-07-20T12:00:00.000Z",
        "record_count": records.count,
        "records": records,
        "metadata": ["source": "DSP fictional showcase data"]
    ]
}

try createDirectory("")

let account: [String: Any] = [
    "id": "720145223846658109",
    "username": "pixelgarden",
    "global_name": "Maya Chen",
    "discriminator": "0",
    "avatar_hash": "",
    "email": "maya@example.invalid",
    "phone": NSNull(),
    "verified": true,
    "premium_type": 2,
    "flags": 0,
    "current_orbs_balance": 4250,
    "connections": [
        ["type": "github", "name": "mayacreates"],
        ["type": "spotify", "name": "Maya's Studio"],
        ["type": "youtube", "name": "Pixel Garden"]
    ],
    "relationships": (1...18).map { ["id": "81\(String(format: "%03d", $0))", "type": $0 == 18 ? 2 : 1] },
    "notes": [
        ["id": "81001", "note": "Met through the design community"],
        ["id": "81003", "note": "Game-night organizer"]
    ],
    "user_sessions": (1...18).map { ["id": "session-\($0)", "status": "inactive"] },
    "guild_settings": (1...8).map { ["guild_id": "500\($0)", "muted": false] },
    "user_activity_application_statistics": (1...12).map {
        ["application_id": "700\($0)", "total_duration": $0 * 3600]
    }
]
try writeJSON(account, to: "Account/user.json")

let applicationNames = [
    "Palette Bot", "Focus Timer", "Garden Radio", "Sketch Relay",
    "Moodboard Keeper", "Studio Queue", "Prompt Library", "Launch Notes"
]
let applicationDescriptions = [
    "Shares accessible color palettes with creative teams.",
    "Runs quiet co-working sessions and focus reminders.",
    "Plays a fictional collection of calm studio playlists.",
    "Coordinates weekly illustration prompts and showcases.",
    "Organizes visual references and project moodboards.",
    "Manages critique requests for a small creative community.",
    "Publishes weekly writing and illustration prompts.",
    "Collects release notes for community-made projects."
]
for index in 1...8 {
    let id = "700\(index)"
    let application: [String: Any] = [
        "id": id,
        "name": applicationNames[index - 1],
        "description": applicationDescriptions[index - 1],
        "icon": NSNull(),
        "bot_token": NSNull(),
        "public_key": NSNull()
    ]
    try writeJSON(application, to: "Account/applications/\(id)/application.json")
    try copyShowcaseImage(to: "Account/applications/\(id)/icon.png")
}

let privateAvatarDirectory = privatePackage.appendingPathComponent("Account/recent_avatars", isDirectory: true)
let privateAvatars = (
    try? fileManager.contentsOfDirectory(
        at: privateAvatarDirectory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
)?.filter { ["png", "jpg", "jpeg", "gif", "webp"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

if privateAvatars.isEmpty {
    for index in 1...4 {
        try copyShowcaseImage(to: "Account/recent_avatars/avatar_202\(7 - index)_0\(index).png")
    }
} else {
    for avatar in privateAvatars {
        let destination = output.appendingPathComponent("Account/recent_avatars/\(avatar.lastPathComponent)")
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.copyItem(at: avatar, to: destination)
    }
}

let privateCurrentAvatar = privatePackage.appendingPathComponent("Account/avatar.png")
if fileManager.fileExists(atPath: privateCurrentAvatar.path) {
    let destination = output.appendingPathComponent("Account/avatar.png")
    try fileManager.copyItem(at: privateCurrentAvatar, to: destination)
} else {
    try copyShowcaseImage(to: "Account/avatar.png")
}

let payments: [[String: Any]] = (1...12).map { index in
    [
        "id": String(format: "pay-%03d", index),
        "created_at": String(format: "2025-%02d-12T10:00:00.000Z", index),
        "currency": index.isMultiple(of: 4) ? "discord_orb" : "usd",
        "amount": index.isMultiple(of: 4) ? 1400 : (index.isMultiple(of: 3) ? 499 : 999),
        "status": 1,
        "description": index.isMultiple(of: 4) ? "Fictional reward credit" : (index.isMultiple(of: 3) ? "Server boost" : "Nitro monthly")
    ]
}
try writeJSON(billingExport(section: "payments", records: payments), to: "Account/user_data_exports/discord_billing/payments.json")
try writeJSON(
    billingExport(section: "entitlements", records: (1...36).map {
        ["sku_id": "sku-\($0)", "type": 1, "consumed": $0.isMultiple(of: 2)]
    }),
    to: "Account/user_data_exports/discord_billing/entitlements.json"
)
try writeJSON(
    billingExport(section: "payment_sources", records: [
        ["id": "demo-source", "type": 1, "country": "US", "deleted_at": NSNull()]
    ]),
    to: "Account/user_data_exports/discord_billing/payment_sources.json"
)
try writeJSON(
    billingExport(section: "billing_profile", records: [["payout_account_status": 0]]),
    to: "Account/user_data_exports/discord_billing/billing_profile.json"
)

let quests: [[String: Any]] = (1...48).map { index in
    [
        "quest_id": "quest-\(index)",
        "user_id": "720145223846658109",
        "enrolled_at": "2025-0\((index % 9) + 1)-04T12:00:00.000Z",
        "completed_at": index <= 41 ? "2025-0\((index % 9) + 1)-05T12:00:00.000Z" : NSNull(),
        "claimed_at": index <= 37 ? "2025-0\((index % 9) + 1)-06T12:00:00.000Z" : NSNull(),
        "orb_quantity_claimed": index <= 37 ? 250 : 0,
        "progress": index <= 41 ? 100 : 45
    ]
}
try writeJSON(quests, to: "Ads/quests_user_status.json")
try writeJSON(
    [
        "age_group": "adult",
        "settings_locale": "en-US",
        "primary_platform_l30": "desktop",
        "genre_names_l90": ["Creative", "Cozy", "Strategy"],
        "theme_names_l90": ["Art", "Design", "Community"]
    ],
    to: "Ads/traits.json"
)

struct ServerDefinition {
    let id: String
    let name: String
    let channels: [(id: String, name: String)]
}

let servers = [
    ServerDefinition(id: "5001", name: "Design Studio", channels: [("5101", "general"), ("5102", "showcase"), ("5103", "critique")]),
    ServerDefinition(id: "5002", name: "Cozy Game Club", channels: [("5201", "lounge"), ("5202", "game-night"), ("5203", "recommendations")]),
    ServerDefinition(id: "5003", name: "Indie Makers", channels: [("5301", "build-log"), ("5302", "feedback"), ("5303", "launches")]),
    ServerDefinition(id: "5004", name: "City Photowalks", channels: [("5401", "meetups"), ("5402", "photo-drops"), ("5403", "gear-talk")]),
    ServerDefinition(id: "5005", name: "Creative Coding Lab", channels: [("5501", "experiments"), ("5502", "help-desk"), ("5503", "resources")]),
    ServerDefinition(id: "5006", name: "Book & Coffee Club", channels: [("5601", "reading-room"), ("5602", "monthly-picks"), ("5603", "off-topic")]),
    ServerDefinition(id: "5007", name: "Animation Workshop", channels: [("5701", "work-in-progress"), ("5702", "references"), ("5703", "screenings")]),
    ServerDefinition(id: "5008", name: "Community Garden", channels: [("5801", "garden-chat"), ("5802", "plant-help"), ("5803", "harvests")])
]
try writeJSON(Dictionary(uniqueKeysWithValues: servers.map { ($0.id, $0.name) }), to: "Servers/index.json")

struct ImportedEmoji {
    let id: String
    let name: String
    let source: URL
    let animated: Bool
}

var importedEmojis: [ImportedEmoji] = []
let privateServers = privatePackage.appendingPathComponent("Servers", isDirectory: true)
if let enumerator = fileManager.enumerator(
    at: privateServers,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles]
) {
    var emojiFiles: [URL] = []
    for case let file as URL in enumerator {
        let ext = file.pathExtension.lowercased()
        if file.deletingLastPathComponent().lastPathComponent == "emoji",
           ["png", "jpg", "jpeg", "gif", "webp"].contains(ext) {
            emojiFiles.append(file)
        }
    }
    for (index, source) in emojiFiles.sorted(by: { $0.path < $1.path }).prefix(24).enumerated() {
        importedEmojis.append(
            ImportedEmoji(
                id: source.deletingPathExtension().lastPathComponent,
                name: String(format: "showcase_%02d", index + 1),
                source: source,
                animated: source.pathExtension.lowercased() == "gif"
            )
        )
    }
}

if importedEmojis.isEmpty {
    for index in 1...8 {
        let id = "910\(String(format: "%02d", index))"
        try copyShowcaseImage(to: "Servers/5001/emoji/\(id).png")
        importedEmojis.append(
            ImportedEmoji(
                id: id,
                name: String(format: "showcase_%02d", index),
                source: output.appendingPathComponent("Servers/5001/emoji/\(id).png"),
                animated: false
            )
        )
    }
} else {
    for emoji in importedEmojis {
        let destination = output.appendingPathComponent(
            "Servers/5001/emoji/\(emoji.id).\(emoji.source.pathExtension.lowercased())"
        )
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.copyItem(at: emoji.source, to: destination)
    }
}

var messagePhrases = [
    "The color study looks wonderful, especially the softer blue.",
    "I shared the updated draft in the showcase channel.",
    "Thanks for the thoughtful feedback — I will revise it tonight.",
    "The spacing feels much clearer now and the hierarchy makes sense.",
    "Would anyone like to join the creative session tomorrow?",
    "This is such a calm and friendly community.",
    "I finished the illustration and exported the final version.",
    "The new layout is simple, readable, and easy to navigate.",
    "Great idea! Let us collect references before the next meeting.",
    "I found a useful guide at https://developer.apple.com/design/",
    "Here is the inspiration board: https://www.figma.com/community",
    "The accessibility pass improved contrast and text clarity.",
    "I can help test the next build on my laptop.",
    "Let us keep the main navigation short and predictable."
]
for emoji in importedEmojis {
    let marker = emoji.animated ? "a" : ""
    let token = "<\(marker):\(emoji.name):\(emoji.id)>"
    messagePhrases.append("This deserves a reaction \(token)")
    messagePhrases.append("The latest update looks excellent \(token) \(token)")
}

var nextMessageID: UInt64 = 1_000_000
let popularHours = [9, 11, 14, 18, 18, 18, 20, 21]

func generatedMessages(seed: Int, count: Int) -> [[String: Any]] {
    (0..<count).map { index in
        nextMessageID += 1
        let year = 2021 + ((index + seed) % 6)
        let month = ((index * 3 + seed) % 12) + 1
        let day = ((index * 5 + seed) % 27) + 1
        let hour = popularHours[(index + seed) % popularHours.count]
        let minute = (index * 7 + seed) % 60
        return [
            "ID": nextMessageID,
            "Timestamp": String(format: "%04d-%02d-%02d %02d:%02d:00", year, month, day, hour, minute),
            "Contents": messagePhrases[(index + seed) % messagePhrases.count],
            "Attachments": index.isMultiple(of: 13) ? "https://cdn.example.invalid/demo-image-\(index).png" : ""
        ]
    }
}

for (serverIndex, server) in servers.enumerated() {
    try writeJSON(["id": server.id, "name": server.name], to: "Servers/\(server.id)/guild.json")
    try writeJSON([], to: "Servers/\(server.id)/audit-log.json")
    for (channelIndex, channel) in server.channels.enumerated() {
        let channelObject: [String: Any] = [
            "id": channel.id,
            "type": 0,
            "name": channel.name,
            "guild_id": server.id
        ]
        try writeJSON(channelObject, to: "Servers/\(server.id)/\(channel.id)/channel.json")
        try writeJSON(
            generatedMessages(seed: serverIndex * 11 + channelIndex * 3, count: 72 - channelIndex * 8),
            to: "Servers/\(server.id)/\(channel.id)/messages.json"
        )
    }
}

let directMessages = [
    ("9001", "Alex Rivera"),
    ("9002", "Noor Patel"),
    ("9003", "Sam Wilson"),
    ("9004", "Jamie & Taylor"),
    ("9005", "Creative Study Group"),
    ("9006", "Morgan Lee"),
    ("9007", "Priya Sharma"),
    ("9008", "Weekend Sketchers"),
    ("9009", "Jordan Kim"),
    ("9010", "Taylor Brooks"),
    ("9011", "Photography Friends"),
    ("9012", "Launch Team")
]
try writeJSON(
    Dictionary(uniqueKeysWithValues: directMessages.map { ($0.0, "Direct Message with \($0.1)") }),
    to: "Messages/index.json"
)
for (index, conversation) in directMessages.enumerated() {
    let channel: [String: Any] = [
        "id": conversation.0,
        "type": index >= 3 ? 3 : 1,
        "name": conversation.1,
        "recipients": conversation.1
            .components(separatedBy: " & ")
            .map { ["username": $0.lowercased().replacingOccurrences(of: " ", with: "_"), "global_name": $0] }
    ]
    try writeJSON(channel, to: "Messages/c\(conversation.0)/channel.json")
    try writeJSON(
        generatedMessages(seed: 90 + index * 7, count: 58 - (index % 4) * 6),
        to: "Messages/c\(conversation.0)/messages.json"
    )
}

let tickets: [String: Any] = [
    "demo-1001": [
        "ticket_id": 1001,
        "status": "closed",
        "subject": "Question about downloading account data",
        "created_at": "2025-02-12T09:15:00.000Z",
        "comments": [
            ["author": "Maya", "comment": "Hello! I would like to confirm which export option includes my message history.", "created_at": "2025-02-12T09:15:00.000Z"],
            ["author": "Discord Support", "comment": "Choose the full data package option. It includes account, server, and message records.", "created_at": "2025-02-12T11:42:00.000Z"],
            ["author": "Maya", "comment": "Perfect, thank you for the clear explanation.", "created_at": "2025-02-12T12:05:00.000Z"]
        ]
    ],
    "demo-1002": [
        "ticket_id": 1002,
        "status": "closed",
        "subject": "Developer application verification",
        "created_at": "2025-09-03T14:20:00.000Z",
        "comments": [
            ["author": "Maya", "comment": "I am testing a small community application and have a question about verification.", "created_at": "2025-09-03T14:20:00.000Z"],
            ["author": "Discord Support", "comment": "We have shared the relevant developer documentation and next steps.", "created_at": "2025-09-04T08:30:00.000Z"]
        ]
    ],
    "demo-1003": [
        "ticket_id": 1003,
        "status": "closed",
        "subject": "Restoring access to a community",
        "created_at": "2025-11-18T10:10:00.000Z",
        "comments": [
            ["author": "Maya", "comment": "A community disappeared from my list after I changed devices. Could you help me understand the available recovery options?", "created_at": "2025-11-18T10:10:00.000Z"],
            ["author": "Discord Support", "comment": "Please ask a community moderator for a fresh invitation. Communities are not restored automatically from account exports.", "created_at": "2025-11-18T15:25:00.000Z"]
        ]
    ],
    "demo-1004": [
        "ticket_id": 1004,
        "status": "closed",
        "subject": "Clarification about billing history",
        "created_at": "2026-01-07T07:45:00.000Z",
        "comments": [
            ["author": "Maya", "comment": "Where can I review the invoices associated with my subscription?", "created_at": "2026-01-07T07:45:00.000Z"],
            ["author": "Discord Support", "comment": "Open User Settings, select Billing, and review the transaction history shown there.", "created_at": "2026-01-07T09:12:00.000Z"],
            ["author": "Maya", "comment": "Found it. Thank you!", "created_at": "2026-01-07T09:30:00.000Z"]
        ]
    ],
    "demo-1005": [
        "ticket_id": 1005,
        "status": "open",
        "subject": "Question about an application command",
        "created_at": "2026-06-15T13:05:00.000Z",
        "comments": [
            ["author": "Maya", "comment": "A test command is not appearing in my private development server.", "created_at": "2026-06-15T13:05:00.000Z"],
            ["author": "Discord Support", "comment": "Please confirm that the application was installed with the applications.commands scope and allow time for global commands to update.", "created_at": "2026-06-15T17:40:00.000Z"]
        ]
    ]
]
try writeJSON(tickets, to: "Support_Tickets/tickets.json")

let readme = """
DSP showcase package
==========================

The account details, messages, servers, billing records, quests, and support
conversations in this folder are fictional demonstration data.

Profile pictures and selected custom emoji image files are copied from the local
package-2 export for visual showcase purposes.

To regenerate it, run:
    swift Scripts/generate_demo_package.swift
"""
try readme.write(to: output.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)

print("Created expanded showcase package at \(output.path)")
