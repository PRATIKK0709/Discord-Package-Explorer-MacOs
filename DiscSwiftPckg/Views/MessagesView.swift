import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Messages")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                // Stats cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MsgStatCard(title: "Total Messages", value: viewModel.formatNumber(viewModel.stats.messageCount), color: .blue)
                    MsgStatCard(title: "DM Messages", value: viewModel.formatNumber(viewModel.stats.dmMessages), color: .indigo)
                    MsgStatCard(title: "Server Messages", value: viewModel.formatNumber(viewModel.stats.serverMessages), color: .orange)
                    MsgStatCard(title: "Total Words", value: viewModel.formatNumber(viewModel.stats.wordCount), color: .purple)
                    MsgStatCard(title: "Conversations", value: "\(viewModel.stats.dmConversations + viewModel.stats.groupDMCount)", color: .pink)
                    MsgStatCard(title: "Channels Used", value: "\(viewModel.stats.serverChannelCount)", color: .green)
                }
                
                // Top DMs
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top DM Conversations")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if viewModel.stats.topDMs.isEmpty {
                        Text("No DM data available")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(Array(viewModel.stats.topDMs.enumerated()), id: \.offset) { idx, dm in
                            DetailedStatsRow(rank: idx + 1, stats: dm)
                        }
                    }
                }
                .padding(20)
                .background(Theme.bgSecondary)
                .cornerRadius(12)
                
                // Top Servers
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Servers")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if viewModel.stats.topServers.isEmpty {
                        Text("No server data available")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(Array(viewModel.stats.topServers.enumerated()), id: \.offset) { idx, srv in
                            DetailedStatsRow(rank: idx + 1, stats: srv)
                        }
                    }
                }
                .padding(20)
                .background(Theme.bgSecondary)
                .cornerRadius(12)
                
                
                // --- Word Analysis Section ---
                Text("Word Analysis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)
                
                HStack(alignment: .top, spacing: 16) {
                    // Top Words
                    StatsList(title: "Favorite Words", data: viewModel.stats.topWords)
                    
                    // Cursed Words
                    StatsList(title: "Cursed Words", data: viewModel.stats.topCursedWords)
                }
                
                // --- Link Analysis Section ---
                Text("Link Analysis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)
                
                HStack(alignment: .top, spacing: 16) {
                    // Top Links
                    StatsList(title: "Top Links", data: viewModel.stats.topLinks)
                    
                    // Discord Links
                    StatsList(title: "Discord Invites", data: viewModel.stats.topDiscordLinks)
                }
                
                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Theme.bgPrimary)
    }
}

// Helper View for Lists
struct StatsList: View {
    let title: String
    let data: [(String, Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            
            if data.isEmpty {
                Text("No data available")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                ForEach(Array(data.prefix(10).enumerated()), id: \.offset) { idx, item in
                    HStack {
                        Text("\(idx + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        
                        Text(item.0)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Text("\(item.1)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(10)
                    .background(idx % 2 == 0 ? Theme.bgSecondary : .clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

struct MsgStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
    }
}

struct DetailedStatsRow: View {
    let rank: Int
    let stats: DetailedStats
    @State private var showDetails = false
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            
            Text(stats.name)
                .font(.system(size: 13))
                .lineLimit(1)
            
            Spacer()
            
            // Preview Stats
            if !stats.topEmojis.isEmpty {
                Text(stats.topEmojis.first?.name ?? "")
                     .font(.caption2)
                     .padding(4)
                     .background(Theme.bgTertiary)
                     .cornerRadius(4)
            }
            
            Text("\(stats.messageCount) msgs")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .background(rank % 2 == 0 ? Theme.bgTertiary : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            DetailedStatsView(stats: stats, rank: rank)
        }
    }
}

#Preview {
    MessagesView()
        .environmentObject(PackageViewModel())
}
