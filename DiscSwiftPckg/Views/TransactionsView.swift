import SwiftUI

struct TransactionsView: View {
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
                .foregroundStyle(Theme.accent)
                .frame(width: 64, height: 64)
                .background(Theme.bgTertiary)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent on Discord")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                
                Text(totalSpent)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            Spacer()
        }
        .padding(24)
        .background(Theme.bgSecondary)
        .cornerRadius(16)
    }
}

// Removed TransactionRow and StatusBadge as they are no longer used for the summary logic

