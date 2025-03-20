import Foundation

extension Double {
    func formattedAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.currencySymbol = "₽"
        formatter.currencyDecimalSeparator = ","
        formatter.currencyGroupingSeparator = "."
        
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f ₽", self)
    }
}
