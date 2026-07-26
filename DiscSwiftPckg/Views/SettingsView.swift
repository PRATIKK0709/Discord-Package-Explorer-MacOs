import SwiftUI

/// Kept as a lightweight informational view for compatibility with older previews.
/// Appearance controls were intentionally removed: the application now has one
/// consistent, accessible light presentation.
struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ABOUT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(theme.accent)
                Text("DSP")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("A local reader for Discord data exports.")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Label("All processing happens on this Mac.", systemImage: "lock.fill")
                Label("The app does not upload or retain your package.", systemImage: "icloud.slash")
                Label("Open another package from the sidebar at any time.", systemImage: "arrow.up.doc")
            }
            .font(.system(size: 12))
            .foregroundStyle(theme.textPrimary)

            Link("View the project on GitHub", destination: URL(string: "https://github.com/PRATIKK0709/Discord-Package-Explorer-MacOs")!)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.accent)

            Spacer()
        }
        .padding(42)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bgPrimary)
    }
}
