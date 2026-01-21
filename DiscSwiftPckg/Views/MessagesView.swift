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
                            HStack {
                                Text("\(idx + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24)
                                
                                Text(dm.name)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(dm.messageCount) messages")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(12)
                            .background(idx % 2 == 0 ? Theme.bgSecondary : .clear)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
                .background(Theme.bgSecondary)
                .cornerRadius(12)
                
                // Top Server Channels
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Server Channels")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if viewModel.stats.topChannels.isEmpty {
                        Text("No channel data available")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(Array(viewModel.stats.topChannels.enumerated()), id: \.offset) { idx, ch in
                            HStack {
                                Text("\(idx + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("#\(ch.0)")
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                    Text(ch.1)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text("\(ch.2) messages")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(12)
                            .background(idx % 2 == 0 ? Theme.bgSecondary : .clear)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
                .background(Theme.bgSecondary)
                .cornerRadius(12)
                
                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Theme.bgPrimary)
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

#Preview {
    MessagesView()
        .environmentObject(PackageViewModel())
}
