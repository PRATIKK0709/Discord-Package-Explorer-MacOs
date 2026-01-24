import SwiftUI
import Combine

enum ThemeProfile: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case discord = "Discord"
    
    var id: String { rawValue }
}

class ThemeManager: ObservableObject {
    @Published var currentProfile: ThemeProfile {
        didSet {
            UserDefaults.standard.set(currentProfile.rawValue, forKey: "selectedTheme")
        }
    }
    
    init() {
        // storage init
        if let saved = UserDefaults.standard.string(forKey: "selectedTheme"),
           let profile = ThemeProfile(rawValue: saved) {
            self.currentProfile = profile
        } else {
            self.currentProfile = .standard
        }
    }
    
    // Derived Colors
    var bgPrimary: Color {
        currentProfile == .discord ? Color(hex: 0x36393f) : Color(hex: 0xFFFFFF)
    }
    
    var bgSecondary: Color {
        currentProfile == .discord ? Color(hex: 0x2f3136) : Color(hex: 0xF5F5F7)
    }
    
    var bgTertiary: Color {
        currentProfile == .discord ? Color(hex: 0x202225) : Color(hex: 0xE5E5EB)
    }
    
    var textPrimary: Color {
        currentProfile == .discord ? Color(hex: 0xFFFFFF) : Color(hex: 0x000000)
    }
    
    var textSecondary: Color {
        currentProfile == .discord ? Color(hex: 0xb9bbbe) : Color(hex: 0x6E6E73)
    }
    
    var accent: Color {
        currentProfile == .discord ? Color(hex: 0x5865F2) : Color(hex: 0xFF9500)
    }
    
    var border: Color {
        currentProfile == .discord ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    
    var cardBg: Color {
        currentProfile == .discord ? Color(hex: 0x40444b) : Color.white
    }
}
