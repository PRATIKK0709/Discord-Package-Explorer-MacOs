import SwiftUI

struct TicketsView: View {
    let tickets: [DiscordTicket]
    @State private var selectedTicket: DiscordTicket?
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar List
            VStack(alignment: .leading, spacing: 0) {
                Text("Support Tickets")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(16)
                
                Divider().background(Theme.bgTertiary)
                
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
            .background(Theme.bgSecondary)
            
            Divider().background(Theme.bgTertiary)
            
            // Detail View
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                
                if let ticket = selectedTicket {
                    TicketDetailView(ticket: ticket)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.textSecondary)
                        Text("Select a ticket to view conversation")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
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

struct TicketRow: View {
    let ticket: DiscordTicket
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ticket.subject ?? "No Subject")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textPrimary.opacity(0.8))
                .lineLimit(1)
            
            HStack {
                Text(ticket.status.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(statusColor(ticket.status))
                
                Spacer()
                
                Text(ticket.formattedDate)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(12)
        .background(isSelected ? Theme.bgTertiary : Color.clear)
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
    let ticket: DiscordTicket
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(ticket.subject ?? "Ticket #\(ticket.id)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                HStack(spacing: 12) {
                    Label(ticket.status.capitalized, systemImage: "circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    
                    Label("\(ticket.messages.count) messages", systemImage: "bubble.left.and.bubble.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgSecondary)
            
            Divider().background(Theme.bgTertiary)
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(ticket.sortedMessages) { msg in
                        TicketMessageRow(message: msg)
                    }
                }
                .padding(24)
            }
        }
    }
}

struct TicketMessageRow: View {
    let message: TicketMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Avatar
            AsyncImage(url: URL(string: message.author.avatar ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(message.author.bot == true ? Theme.accent : Theme.bgTertiary)
                    .overlay(Text(String(message.author.username.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(message.author.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    if message.author.bot == true {
                        Text("BOT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Theme.accent)
                            .cornerRadius(4)
                    }
                    
                    Text(formatDate(message.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                
                if let attachments = message.attachments, !attachments.isEmpty {
                    ForEach(attachments, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            Link(destination: url) {
                                Label("Attachment", systemImage: "paperclip")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.accent)
                        }
                    }
                }
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
