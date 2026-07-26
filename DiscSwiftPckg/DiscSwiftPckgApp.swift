import SwiftUI

@main
struct DiscSwiftPckgApp: App {
    @StateObject private var viewModel = PackageViewModel()
    @StateObject private var theme = ThemeManager()
    
    var body: some Scene {
        WindowGroup("DSP") {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(theme)
                .preferredColorScheme(theme.currentProfile == .discord ? .dark : .light)
        }
        .windowResizability(.contentSize)
    }
}
