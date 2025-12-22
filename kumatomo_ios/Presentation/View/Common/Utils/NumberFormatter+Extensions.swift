import Foundation

extension Int {
    func formatCount() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0

        let absValue = abs(self)

        switch absValue {
        case 0 ..< 1_000:
            return "\(self)"
        case 1_000 ..< 1_000_000:
            let thousands = Double(self) / 1_000.0
            if thousands.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(thousands))K"
            } else {
                return String(format: "%.1fK", thousands)
            }
        case 1_000_000 ..< 1_000_000_000:
            let millions = Double(self) / 1_000_000.0
            if millions.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(millions))M"
            } else {
                return String(format: "%.1fM", millions)
            }
        default:
            let billions = Double(self) / 1_000_000_000.0
            if billions.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(billions))B"
            } else {
                return String(format: "%.1fB", billions)
            }
        }
    }
}

extension Int? {

    func formatCount() -> String {
        return (self ?? 0).formatCount()
    }
}
