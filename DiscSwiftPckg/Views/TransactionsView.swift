import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var theme: ThemeManager
    let payments: [DiscordPayment]
    
    // Calculate total spent by currency - Simplified for mainly USD as per example
    var totalSpent: String {
        let total = payments
            .filter { $0.status == 1 }
            .compactMap { $0.amount }
            .reduce(0, +)
        
        let doubleTotal = Double(total) / 100.0
        return String(format: "$%.2f", doubleTotal)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "banknote.fill")
                .font(.system(size: 32))
                .foregroundStyle(theme.accent)
                .frame(width: 64, height: 64)
                .overlay(Rectangle().stroke(theme.border))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent on Discord")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                
                Text(totalSpent)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
            }
            
            Spacer()
        }
        .padding(24)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }
}

// Removed TransactionRow and StatusBadge as they are no longer used for the summary logic
