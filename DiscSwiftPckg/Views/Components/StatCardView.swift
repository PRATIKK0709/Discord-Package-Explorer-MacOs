import SwiftUI

struct StatCardView: View {
    @EnvironmentObject var theme: ThemeManager
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.22), theme.border.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color(hex: 0x35415D).opacity(0.06), radius: 12, x: 0, y: 5)
    }
}

#Preview {
    HStack {
        StatCardView(
            title: "Total Files",
            value: "12.5K",
            icon: "doc.fill",
            color: .blue,
            subtitle: "in your package"
        )
        StatCardView(
            title: "Conversations",
            value: "847",
            icon: "bubble.left.fill",
            color: .indigo,
            subtitle: "message threads"
        )
    }
    .padding()
    .frame(width: 500)
    .environmentObject(ThemeManager())
}
