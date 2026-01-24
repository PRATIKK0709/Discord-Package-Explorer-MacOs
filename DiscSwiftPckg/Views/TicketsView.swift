import SwiftUI

struct TicketsView: View {
    @EnvironmentObject var theme: ThemeManager
    let tickets: [DiscordTicket]
    @State private var selectedTicket: DiscordTicket?
    
    var body: some View {
        if tickets.isEmpty {
            // Empty State
            VStack(spacing: 16) {
                Image(systemName: "ticket")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.textSecondary)
                Text("No Support Tickets")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text("You don't have any support ticket data in this package.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.bgPrimary)
        } else {
HStack(spacing: 0) {
            // Sidebar List
            VStack(alignment: .leading, spacing: 0) {
                Text("Support Tickets")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .padding(16)
                
                Divider().background(theme.bgTertiary)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(tickets) { ticket in
                            TicketRow(ticket: ticket, isSelected: selectedTicket?.id == ticket.id)
                                .onTapGesture {
                                    selectedTicket = ticket
                                }
                        }
                    }
                }
            }
            .frame(width: 250)
            .background(theme.bgSecondary)
            
            Divider().background(theme.bgTertiary)
            
            // Detail View
            ZStack {
                theme.bgPrimary.ignoresSafeArea()
                
                if let ticket = selectedTicket {
                    TicketDetailView(ticket: ticket)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 48))
                            .foregroundStyle(theme.textSecondary)
                        Text("Select a ticket to view conversation")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            if selectedTicket == nil {
                selectedTicket = tickets.first
            }
        }
        }
    }
}

struct TicketRow: View {
    @EnvironmentObject var theme: ThemeManager
    let ticket: DiscordTicket
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ticket.subject ?? "No Subject")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? theme.textPrimary : theme.textPrimary.opacity(0.8))
                .lineLimit(1)
            
            HStack {
                Text(ticket.status.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(statusColor(ticket.status))
                
                Spacer()
                
                Text(ticket.formattedDate)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(12)
        .background(isSelected ? theme.bgTertiary : Color.clear)
        .contentShape(Rectangle())
    }
    
    func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "open": return .green
        case "closed": return .gray
        default: return .orange
        }
    }
}

struct TicketDetailView: View {
    @EnvironmentObject var theme: ThemeManager
    let ticket: DiscordTicket
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(ticket.subject ?? "Ticket #\(ticket.id)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                
                HStack(spacing: 12) {
                    Label(ticket.status.capitalized, systemImage: "circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.textSecondary)
                    
                    Label("\(ticket.comments.count) comments", systemImage: "bubble.left.and.bubble.right")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.bgSecondary)
            
            Divider().background(theme.bgTertiary)
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(ticket.sortedMessages) { comment in
                        TicketCommentRow(comment: comment)
                    }
                }
                .padding(24)
            }
        }
    }
}

struct TicketCommentRow: View {
    @EnvironmentObject var theme: ThemeManager
    let comment: TicketComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Avatar
            ZStack {
                Circle().fill(theme.bgTertiary)
                    .frame(width: 40, height: 40)
                Text(String(comment.author.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(comment.author)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text(formatDate(comment.createdAt))
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                }
                
                Text(comment.comment)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textPrimary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
    
    func formatDate(_ ts: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: ts) {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return ts
    }
}
