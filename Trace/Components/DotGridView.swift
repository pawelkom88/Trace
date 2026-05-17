import SwiftUI

struct DotGridView: View {
    var body: some View {
        Canvas { context, size in
            let spacingX = size.width / 10
            let spacingY = size.height / 10
            
            // Draw a faint dot at every 10% intersection
            for x in 1...9 {
                for y in 1...9 {
                    let rect = CGRect(
                        x: CGFloat(x) * spacingX - 3,
                        y: CGFloat(y) * spacingY - 3,
                        width: 6, height: 6
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(DesignSystem.ColorToken.accentCyan.opacity(0.4)))
                }
            }
        }
    }
}
