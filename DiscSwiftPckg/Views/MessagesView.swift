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
                    MsgStatCard(title: "Total Messages", value: viewModel.formatNumber(viewModel.stats.messageCount), icon: "bubble.left.and.bubble.right.fill", color: .blue)
                    MsgStatCard(title: "DM Messages", value: viewModel.formatNumber(viewModel.stats.dmMessages), icon: "person.2.fill", color: .indigo)
                    MsgStatCard(title: "Server Messages", value: viewModel.formatNumber(viewModel.stats.serverMessages), icon: "server.rack", color: .orange)
                    MsgStatCard(title: "Total Words", value: viewModel.formatNumber(viewModel.stats.wordCount), icon: "text.quote", color: .purple)
                    MsgStatCard(title: "Conversations", value: "\(viewModel.stats.dmConversations + viewModel.stats.groupDMCount)", icon: "bubble.left.fill", color: .pink)
                    MsgStatCard(title: "Channels Used", value: "\(viewModel.stats.serverChannelCount)", icon: "number", color: .green)
                }
                
                // Top DMs
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.wave.2.fill")
                            .foregroundStyle(Theme.accent)
                        Text("Top DM Conversations")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
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
                .cornerRadius(16)
                
                // Top Servers
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundStyle(Theme.accent)
                        Text("Top Servers")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
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
                .cornerRadius(16)
                
                
                // --- Word Analysis Section ---
                Text("Word Analysis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Top Words
                    RichAnalysisCard(title: "Favorite Words", icon: "text.quote", data: viewModel.stats.topWords, color: .blue)
                    
                    // Cursed Words
                    RichAnalysisCard(title: "Cursed Words", icon: "exclamationmark.triangle.fill", data: viewModel.stats.topCursedWords, color: .red)
                }
                
                // --- Link Analysis Section ---
                Text("Link Analysis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Top Links
                    RichAnalysisCard(title: "Top Links", icon: "link", data: viewModel.stats.topLinks, color: .cyan)
                    
                    // Discord Links
                    RichAnalysisCard(title: "Discord Invites", icon: "person.badge.plus", data: viewModel.stats.topDiscordLinks, color: .indigo)
                }
                
                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Theme.bgPrimary)
    }
}

// Helper View for Lists
struct RichAnalysisCard: View {
    let title: String
    let icon: String // Added icon
    let data: [(String, Int)]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(6)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
            }
            
            if data.isEmpty {
                Text("No data available")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(data.prefix(10).enumerated()), id: \.offset) { idx, item in
                        HStack {
                            Text("\(idx + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(color.opacity(0.8))
                                .frame(width: 20)
                            
                            Text(item.0)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(Theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(item.1)")
                                .font(.system(size: 12, weight: .semibold)) // Bold count
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.bgTertiary)
                                .cornerRadius(4)
                        }
                        .padding(8)
                        .background(idx % 2 == 0 ? Theme.bgTertiary.opacity(0.5) : .clear)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.bgSecondary)
        .cornerRadius(16) // Rounder corners
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

struct MsgStatCard: View {
    let title: String
    let value: String
    let icon: String // Added icon
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .padding(8)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold)) // Slightly smaller but bolder
                    .foregroundStyle(Theme.textPrimary)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgSecondary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
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
