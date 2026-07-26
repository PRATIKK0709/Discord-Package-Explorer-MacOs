import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 28) {
                Text("DSP")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(theme.accent)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Your Discord history,\nmade understandable.")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("A quiet, readable view of the messages, people, communities, and account records inside your Discord data export.")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.textSecondary)
                        .lineSpacing(4)
                        .frame(maxWidth: 480, alignment: .leading)
                }

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    HStack(spacing: 9) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(theme.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 22) {
                    OnboardingFact(icon: "lock.fill", text: "Processed locally")
                    OnboardingFact(icon: "wifi.slash", text: "Works offline")
                    OnboardingFact(icon: "eye.slash", text: "No tracking")
                }
            }
            .padding(64)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            ZStack {
                theme.lavender.opacity(0.45)
                VStack(spacing: 28) {
                    Image(systemName: "text.document")
                        .font(.system(size: 68, weight: .ultraLight))
                        .foregroundStyle(theme.accent)
                    VStack(spacing: 7) {
                        Text("One archive. One clear view.")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Nothing is uploaded.")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
    }
}

private struct OnboardingFact: View {
    @EnvironmentObject private var theme: ThemeManager
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(theme.textSecondary)
    }
}
