import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Activity")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                // Events grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActivityCard(icon: "app.fill", title: "App Opened", value: viewModel.stats.appOpenedCount)
                    ActivityCard(icon: "waveform", title: "Voice Joins", value: viewModel.stats.voiceChannelJoins)
                    ActivityCard(icon: "phone.fill", title: "Calls Joined", value: viewModel.stats.callsJoined)
                    ActivityCard(icon: "face.smiling.fill", title: "Reactions", value: viewModel.stats.reactionsAdded)
                    ActivityCard(icon: "pencil", title: "Messages Edited", value: viewModel.stats.messagesEdited)
                    ActivityCard(icon: "trash", title: "Messages Deleted", value: viewModel.stats.messagesDeleted)
                    ActivityCard(icon: "command", title: "Slash Commands", value: viewModel.stats.slashCommandsUsed)
                    ActivityCard(icon: "bell.fill", title: "Notifications", value: viewModel.stats.notificationsClicked)
                    ActivityCard(icon: "link", title: "Invites Sent", value: viewModel.stats.invitesSent)
                    ActivityCard(icon: "gift.fill", title: "Gifts Sent", value: viewModel.stats.giftsSent)
                    ActivityCard(icon: "magnifyingglass", title: "Searches", value: viewModel.stats.searchesStarted)
                    ActivityCard(icon: "exclamationmark.triangle.fill", title: "App Crashes", value: viewModel.stats.appCrashes)
                }
                
                // Yearly activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Messages by Year")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if viewModel.stats.messagesByYear.isEmpty {
                        Text("No yearly data")
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        YearlyChartView(data: viewModel.stats.messagesByYear)
                            .frame(height: 120)
                    }
                }
                .padding(20)
                .background(Theme.bgSecondary)
                .cornerRadius(12)
                
                // Payments
                if viewModel.stats.paymentCount > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payments")
                            .font(.system(size: 16, weight: .semibold))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Spent")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                                Text(viewModel.stats.formattedTotalSpent)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Transactions")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                                Text("\(viewModel.stats.paymentCount)")
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                    }
                    .padding(20)
                    .background(Theme.bgSecondary)
                    .cornerRadius(12)
                }
                
                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Theme.bgPrimary)
    }
}

struct ActivityCard: View {
    let icon: String
    let title: String
    let value: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
            Text("\(value)")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
    }
}

struct YearlyChartView: View {
    let data: [Int: Int]
    
    var sortedYears: [(Int, Int)] {
        data.sorted { $0.key < $1.key }
    }
    
    var maxVal: Int { data.values.max() ?? 1 }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(sortedYears, id: \.0) { year, count in
                let height = maxVal > 0 ? CGFloat(count) / CGFloat(maxVal) : 0
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(year == sortedYears.max(by: { $0.1 < $1.1 })?.0 ? Theme.accent : Theme.accent.opacity(0.4))
                        .frame(height: max(4, height * 80))
                    Text("\(year)")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ActivityView()
        .environmentObject(PackageViewModel())
}
