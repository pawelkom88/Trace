import SwiftUI

enum DesignSystem {
    enum ColorToken {
        static let backgroundPrimary = Color(white: 0.05)
        static let backgroundSecondary = Color(red: 0.05, green: 0.05, blue: 0.15)
        static let surface = Color.white.opacity(0.1)
        static let surfaceBorder = Color.white.opacity(0.2)
        
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.6)
        
        static let accentBlue = Color(red: 0.2, green: 0.5, blue: 1.0)
        static let accentCyan = Color(red: 0.2, green: 0.9, blue: 1.0)
        
        static let success = Color.green
        static let warning = Color.yellow
        static let danger = Color.red
        
        static let gemPrimary = Color(red: 1.0, green: 0.2, blue: 0.6) // Hot pink / Magenta
        static let gemSecondary = Color(red: 1.0, green: 0.6, blue: 0.8)
        
        static let lifelineWormhole = Color(red: 0.6, green: 0.2, blue: 1.0) // Deep purple
        static let lifelineZen = Color(red: 0.2, green: 0.8, blue: 1.0) // Ice blue
        static let lifelinePhantom = Color(red: 0.2, green: 1.0, blue: 0.6) // Ghost green
    }
    
    enum GradientToken {
        static let primaryCTA = LinearGradient(
            colors: [ColorToken.accentCyan, ColorToken.accentBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gemGradient = LinearGradient(
            colors: [ColorToken.gemSecondary, ColorToken.gemPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gestureTrail = LinearGradient(
            colors: [ColorToken.accentCyan, ColorToken.accentBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let backgroundGlow = RadialGradient(
            colors: [ColorToken.backgroundSecondary, ColorToken.backgroundPrimary],
            center: .center,
            startRadius: 0,
            endRadius: 400
        )
        
        static let successGlow = RadialGradient(
            colors: [ColorToken.success.opacity(0.5), ColorToken.backgroundPrimary],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
        
        static let warningGlow = RadialGradient(
            colors: [ColorToken.warning.opacity(0.5), ColorToken.backgroundPrimary],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let pill: CGFloat = 9999
    }
    
    enum Typography {
        static let title = Font.body.bold()
        static let subtitle = Font.body.weight(.semibold)
        static let body = Font.body
        static let caption = Font.body
        static let heroScore = Font.body.weight(.black)
    }
    
    enum Stroke {
        static let targetPathWidth: CGFloat = 12
        static let livePathWidth: CGFloat = 10
        static let glowPathWidth: CGFloat = 24
        static let startDotSize: CGFloat = 24
        static let endDotSize: CGFloat = 24
    }
    
    enum AnimationDuration {
        static let quick: TimeInterval = 0.2
        static let normal: TimeInterval = 0.35
        static let slow: TimeInterval = 0.6
        static let preview: TimeInterval = 1.5
    }
}
