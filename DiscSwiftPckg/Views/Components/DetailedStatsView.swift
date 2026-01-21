import SwiftUI

struct DetailedStatsView: View {
    let stats: DetailedStats
    let rank: Int?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .center, spacing: 16) {
                    if let rank = rank {
                        Text("#\(rank)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stats.name)
                            .font(.system(size: 24, weight: .bold))
                            .lineLimit(1)
                        
                        Text("\(stats.messageCount) messages")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let server = stats.serverName {
                        Text(server)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.bgTertiary)
                            .cornerRadius(4)
                    }
                }
                .padding(.bottom, 8)
                
                // Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricInfoCard(title: "Words", value: "\(stats.wordCount)", icon: "text.quote")
                    MetricInfoCard(title: "Avg Length", value: String(format: "%.1f", Double(stats.characterCount) / Double(max(1, stats.messageCount))), icon: "ruler")
                    MetricInfoCard(title: "Cursed", value: "\(stats.topCursedWords.map(\.count).reduce(0, +))", icon: "exclamationmark.triangle")
                }
                
                // Top Custom Emojis
                if !stats.topEmojis.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Top Custom Emojis", systemImage: "face.smiling")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(stats.topEmojis, id: \.id) { emoji in
                                    VStack {
                                        AsyncImage(url: URL(string: emoji.imageURL)) { image in
                                            image.resizable().scaledToFit()
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 40, height: 40)
                                        
                                        Text("\(emoji.count)")
                                            .font(.caption)
                                            .bold()
                                    }
                                    .frame(width: 60)
                                    .padding(8)
                                    .background(Theme.bgTertiary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                HStack(alignment: .top, spacing: 24) {
                    // Top Words List
                    if !stats.topWords.isEmpty {
                        SimpleList(title: "Top Words", icon: "text.format", items: stats.topWords)
                    }
                    
                    // Cursed Words List
                    SimpleList(title: "Cursed Words", icon: "mouth", items: stats.topCursedWords)
                }
                
                HStack(alignment: .top, spacing: 24) {
                    // Links
                    if !stats.topLinks.isEmpty {
                        SimpleList(title: "Top Links", icon: "link", items: stats.topLinks)
                    }
                    
                    // Discord Invites
                    if !stats.topDiscordLinks.isEmpty {
                        SimpleList(title: "Discord Invites", icon: "person.badge.plus", items: stats.topDiscordLinks)
                    }
                }
            }
            .padding(32)
        }
        .background(Theme.bgPrimary)
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct MetricInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgSecondary)
        .cornerRadius(8)
    }
}

struct SimpleList: View {
    let title: String
    let icon: String
    let items: [(String, Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            if items.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(Array(items.prefix(10).enumerated()), id: \.offset) { idx, item in
                    HStack {
                        Text("\(idx + 1).")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 24, alignment: .leading)
                        
                        Text(item.0)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Text("\(item.1)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(8)
                    .background(idx % 2 == 0 ? Theme.bgTertiary : .clear)
                    .cornerRadius(4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
