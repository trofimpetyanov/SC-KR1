import Foundation

struct Operation: Identifiable, Codable, Equatable {
    let id: UUID
    let type: OperationType
    let bankAccountId: UUID
    let categoryId: UUID
    var amount: Double
    var date: Date
    var description: String?
    
    init(id: UUID = UUID(), type: OperationType, bankAccountId: UUID, categoryId: UUID, 
         amount: Double, date: Date = Date(), description: String? = nil) {
        self.id = id
        self.type = type
        self.bankAccountId = bankAccountId
        self.categoryId = categoryId
        self.amount = amount
        self.date = date
        self.description = description
    }
    
    static func == (lhs: Operation, rhs: Operation) -> Bool {
        return lhs.id == rhs.id
    }
}
