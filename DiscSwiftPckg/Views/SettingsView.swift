import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("Customize your experience.")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.textSecondary)
                }
                
                // Appearance Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Appearance", systemImage: "paintbrush.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Theme Selector
                        HStack(spacing: 16) {
                            ForEach(ThemeProfile.allCases) { profile in
                                ThemeOptionCard(
                                    profile: profile,
                                    isSelected: theme.currentProfile == profile
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        theme.currentProfile = profile
                                    }
                                }
                            }
                        }
                        
                        Text(theme.currentProfile == .discord ? "Using Discord's dark theme with blurple accents." : "Using the clean light theme.")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(20)
                    .background(theme.bgSecondary)
                    .cornerRadius(12)
                }
                
                // How to Use Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("How to Use", systemImage: "questionmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        StepRow(number: 1, text: "Go to Discord Settings → Privacy & Safety → Request all of my Data.")
                        StepRow(number: 2, text: "Wait for Discord to email you a download link (can take up to 30 days).")
                        StepRow(number: 3, text: "Download and unzip the package folder.")
                        StepRow(number: 4, text: "Drag & Drop the 'package' folder into this app.")
                    }
                    .padding(20)
                    .background(theme.bgSecondary)
                    .cornerRadius(12)
                }
                
                // About Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("About", systemImage: "info.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.accent.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(theme.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Discord Package Explorer")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(theme.textPrimary)
                                Text("Version 1.0.0")
                                    .font(.system(size: 12))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                        
                        Text("An open-source tool to visualize your Discord data. All processing happens locally on your device – your data never leaves your machine.")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.textPrimary.opacity(0.85))
                            .lineSpacing(4)
                        
                        Divider().background(theme.border)
                        
                        Link(destination: URL(string: "https://github.com/PRATIKK0709/Discord-Package-Explorer-MacOs")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                Text("View on GitHub")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.accent)
                        }
                        
                        Text("Created by Pratik Ray • Licensed under MIT")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(20)
                    .background(theme.bgSecondary)
                    .cornerRadius(12)
                }
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
        .background(theme.bgPrimary)
    }
}

// MARK: - Theme Option Card

struct ThemeOptionCard: View {
    @EnvironmentObject var theme: ThemeManager
    let profile: ThemeProfile
    let isSelected: Bool
    let action: () -> Void
    
    var previewColors: (bg: Color, accent: Color, text: Color) {
        switch profile {
        case .standard:
            return (Color(hex: 0xF5F5F7), Color(hex: 0xFF9500), Color(hex: 0x000000))
        case .discord:
            return (Color(hex: 0x36393f), Color(hex: 0x5865F2), Color(hex: 0xFFFFFF))
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Preview Swatch
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(previewColors.bg)
                        .frame(height: 60)
                    
                    HStack(spacing: 8) {
                        Circle().fill(previewColors.accent).frame(width: 16, height: 16)
                        RoundedRectangle(cornerRadius: 4).fill(previewColors.text.opacity(0.3)).frame(width: 40, height: 8)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.accent : theme.border, lineWidth: isSelected ? 2 : 1)
                )
                
                Text(profile.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.accent : theme.textPrimary)
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step Row

struct StepRow: View {
    @EnvironmentObject var theme: ThemeManager
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(theme.accent)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(theme.textPrimary)
        }
    }
}
