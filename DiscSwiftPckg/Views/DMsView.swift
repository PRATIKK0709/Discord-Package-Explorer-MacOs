import SwiftUI

struct DMsView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    @EnvironmentObject var theme: ThemeManager
    @State private var searchText = ""
    
    var filteredDMs: [(name: String, messageCount: Int)] {
        let list = viewModel.stats.dmList
        if searchText.isEmpty {
            return list
        }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Direct Messages")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                
                Spacer()
                
               Text("\(filteredDMs.count) total")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            // Search & Stats Row
            HStack(spacing: 16) {
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.textSecondary)
                    TextField("Search DMs...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(theme.bgSecondary)
                .cornerRadius(8)
                
                // Stats
                HStack(spacing: 12) {
                    DMStatPill(title: "Conversations", value: "\(viewModel.stats.dmConversations)", icon: "person.2.fill", color: .blue)
                    DMStatPill(title: "Total Messages", value: viewModel.formatNumber(viewModel.stats.dmList.reduce(0){ $0 + $1.messageCount }), icon: "bubble.left.fill", color: .purple)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            
            // DM list (Unified Grid)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 16)], spacing: 16) {
                    ForEach(Array(filteredDMs.enumerated()), id: \.offset) { index, dm in
                        DMCard(
                            name: dm.name,
                            messageCount: dm.messageCount,
                            formattedCount: viewModel.formatNumber(dm.messageCount),
                            rank: index + 1
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .background(theme.bgPrimary)
    }
}

struct DMStatPill: View {
    @EnvironmentObject var theme: ThemeManager
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
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.bgSecondary)
        .cornerRadius(6)
    }
}

struct DMCard: View {
    @EnvironmentObject var theme: ThemeManager
    let name: String
    let messageCount: Int
    let formattedCount: String
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: 0xFFD700) // Gold
        case 2: return Color(hex: 0xC0C0C0) // Silver
        case 3: return Color(hex: 0xCD7F32) // Bronze
        default: return theme.textSecondary.opacity(0.3)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(theme.bgSecondary)
                    .frame(width: 24, height: 24)
                
                if rank <= 3 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(rankColor)
                } else {
                    Text("#\(rank)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            
            // Initial
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                
                Text("\(formattedCount) msgs")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(theme.cardBg)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(theme.border.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    DMsView()
        .environmentObject(PackageViewModel())
}
