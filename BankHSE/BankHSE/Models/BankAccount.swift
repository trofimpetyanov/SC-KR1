import Foundation

struct BankAccount: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var balance: Double
    
    init(id: UUID = UUID(), name: String, balance: Double = 0) {
        self.id = id
        self.name = name
        self.balance = balance
    }
    
    static func == (lhs: BankAccount, rhs: BankAccount) -> Bool {
        return lhs.id == rhs.id
    }
}
