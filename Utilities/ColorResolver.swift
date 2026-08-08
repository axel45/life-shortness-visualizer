import SwiftUI

enum DotColor {
    case future
    case unrecorded
    case lowRating   // rating 1-2
    case gray        // kept for backward compatibility (rating < 3 but >= 0 with no specific rating)
    case white
    case silver
    case gold
}

enum ColorResolver {

    static func dotColor(for weekRecord: WeekRecord?, isFuture: Bool) -> DotColor {
        // Fix 14: Future weeks use 'future' color (visually dimmed)
        if isFuture { return .future }

        // Fix 4 & Fix 6: distinguish unrecorded from low-rating
        guard let record = weekRecord else { return .unrecorded }
        guard let avg = record.averageStars else { return .unrecorded }

        switch avg {
        case ..<3.0: return .lowRating  // Fix 6: rating 1-2 gets distinct color
        case 3.0..<4.0: return .white
        case 4.0..<5.0: return .silver
        default: return .gold
        }
    }

    static func color(for dotColor: DotColor) -> (fill: Color, stroke: Color?) {
        switch dotColor {
        case .future:
            // Fix 4: light gray #D1D1D6
            return (fill: Color(hex: "D1D1D6"), stroke: nil)
        case .unrecorded:
            // Fix 4: off-white #F2F2F7
            return (fill: Color(hex: "F2F2F7"), stroke: nil)
        case .lowRating:
            // Fix 6: light red/orange #FFD5CC
            return (fill: Color(hex: "FFD5CC"), stroke: nil)
        case .gray:
            // legacy fallback
            return (fill: Color(white: 0.45), stroke: nil)
        case .white:
            return (fill: Color.white, stroke: nil)
        case .silver:
            return (fill: Color(white: 0.75), stroke: nil)
        case .gold:
            return (fill: Color(red: 1.0, green: 0.84, blue: 0.0), stroke: nil)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(r * 255), gi = Int(g * 255), bi = Int(b * 255)
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
