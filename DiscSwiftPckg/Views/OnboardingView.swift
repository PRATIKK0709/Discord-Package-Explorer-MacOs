import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var theme: ThemeManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep = 0
    
    var body: some View {
        ZStack {
            theme.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    PrivacyStep()
                        .tag(1)
                    
                    GetStartedStep(onComplete: {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    })
                        .tag(2)
                }
                .tabViewStyle(.automatic)
                .animation(.easeInOut, value: currentStep)
                
                // Navigation Dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(currentStep == index ? theme.accent : theme.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 24)
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if currentStep < 2 {
                        Button(action: {
                            withAnimation { currentStep += 1 }
                        }) {
                            HStack(spacing: 6) {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(theme.accent)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .frame(width: 1050, height: 750)
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.accent)
            }
            
            VStack(spacing: 12) {
                Text("Discord Package Explorer")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                
                Text("Visualize and analyze your Discord data like never before.")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Spacer()
        }
        .padding(40)
    }
}

// MARK: - Privacy Step

struct PrivacyStep: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                
                VStack(spacing: 12) {
                    Text("Your Data Stays Private")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("Everything is processed locally on your machine.\nNo data is ever uploaded to any server.")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 450)
                }
            }
            
            // Feature List
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "internaldrive", text: "100% offline processing")
                FeatureRow(icon: "eye.slash", text: "No telemetry or analytics")
                FeatureRow(icon: "trash", text: "Close the app and your data is gone")
            }
            .padding(24)
            .background(theme.bgSecondary)
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(40)
    }
}

struct FeatureRow: View {
    @EnvironmentObject var theme: ThemeManager
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(theme.textPrimary)
        }
    }
}

// MARK: - Get Started Step

struct GetStartedStep: View {
    @EnvironmentObject var theme: ThemeManager
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.accent)
                
                VStack(spacing: 12) {
                    Text("Ready to Explore")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("Request your data from Discord, then drop the\n'package' folder into this app to begin.")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 450)
                }
            }
            
            Button(action: onComplete) {
                HStack(spacing: 8) {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(theme.accent)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(40)
    }
}
