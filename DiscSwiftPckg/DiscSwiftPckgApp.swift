import SwiftUI

@main
struct DiscSwiftPckgApp: App {
    @StateObject private var viewModel = PackageViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1000, height: 700)
    }
}
