import SwiftUI

struct ServersView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    @State private var searchText = ""
    
    var filteredServers: [(name: String, messageCount: Int)] {
        let list = viewModel.stats.serverList
        if searchText.isEmpty {
            return list
        }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Servers")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.stats.serverList.count) total")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            // Search & Stats Row
            HStack(spacing: 16) {
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.textSecondary)
                    TextField("Search servers...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Theme.bgSecondary)
                .cornerRadius(8)
                
                // key stats
                HStack(spacing: 12) {
                     ServerStatPill(title: "Muted", value: "\(viewModel.stats.mutedServerCount)", icon: "speaker.slash.fill", color: .red) // Only keep mute as it's useful
                     ServerStatPill(title: "Total Messages", value: viewModel.formatNumber(viewModel.stats.serverMessages), icon: "bubble.left.fill", color: .purple)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            
            // Server list (Unified Grid)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 16)], spacing: 16) {
                    ForEach(Array(filteredServers.enumerated()), id: \.element.name) { index, server in
                        ServerCard(
                            name: server.name,
                            messageCount: server.messageCount,
                            formattedCount: viewModel.formatNumber(server.messageCount),
                            rank: index + 1
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.bgPrimary)
    }
}

struct ServerStatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 12, weight: .bold))
            
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.bgSecondary)
        .cornerRadius(6)
    }
}

struct ServerCard: View {
    let name: String
    let messageCount: Int
    let formattedCount: String
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: 0xFFD700) // Gold
        case 2: return Color(hex: 0xC0C0C0) // Silver
        case 3: return Color(hex: 0xCD7F32) // Bronze
        default: return Theme.textSecondary.opacity(0.3)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(Theme.bgSecondary)
                    .frame(width: 24, height: 24)
                
                if rank <= 3 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(rankColor)
                } else {
                    Text("#\(rank)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            // Initial
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                
                Text("\(formattedCount) msgs")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.border.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    ServersView()
        .environmentObject(PackageViewModel())
}
