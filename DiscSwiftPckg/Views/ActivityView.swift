import SwiftUI

enum TimeFrame: String, CaseIterable, Identifiable {
    case hourly = "Hourly"
    case daily = "Daily"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { self.rawValue }
}

struct ActivityView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    @State private var selectedTimeFrame: TimeFrame = .daily
    
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
                
                // Activity Graph Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Message Activity")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        
                        Spacer()
                        
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases) { frame in
                                Text(frame.rawValue).tag(frame)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 300)
                    }
                    
                    UniversalBarChart(data: chartData, maxVal: maxChartValue)
                        .frame(height: 180)
                        .padding(.top, 8)
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
    
    // Computed props for chart data
    private var chartData: [(String, Int)] {
        switch selectedTimeFrame {
        case .hourly:
            return viewModel.stats.messagesByHour.enumerated().map { (String(format: "%02d", $0), $1) }
        case .daily:
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            return viewModel.stats.messagesByDay.enumerated().map { (days[$0], $1) }
        case .monthly:
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return viewModel.stats.messagesByMonth.enumerated().map { (months[$0], $1) }
        case .yearly:
            return viewModel.stats.messagesByYear.sorted { $0.key < $1.key }.map { (String($0.key), $0.value) }
        }
    }
    
    private var maxChartValue: Int {
        chartData.map { $0.1 }.max() ?? 1
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

struct UniversalBarChart: View {
    let data: [(String, Int)]
    let maxVal: Int
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.0) { label, value in
                    let height = maxVal > 0 ? (CGFloat(value) / CGFloat(maxVal)) * geo.size.height : 0
                    
                    VStack(spacing: 6) {
                        // Tooltip-ish value on top if selected (simplified for now)
                        
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.accent.opacity(0.8), Theme.accent.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(4, height))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                            .fixedSize()
                            .rotationEffect(data.count > 15 ? .degrees(-45) : .degrees(0))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    ActivityView()
        .environmentObject(PackageViewModel())
}
