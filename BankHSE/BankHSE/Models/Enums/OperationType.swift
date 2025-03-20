import Foundation

enum OperationType: String, Codable, CaseIterable {
    case income
    case expense
    
    var displayName: String {
        switch self {
        case .income:
            return "Доход"
        case .expense:
            return "Расход"
        }
    }
}
