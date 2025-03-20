import Foundation

struct Category: Identifiable, Codable, Equatable {
    let id: UUID
    let type: OperationType
    var name: String
    
    init(id: UUID = UUID(), type: OperationType, name: String) {
        self.id = id
        self.type = type
        self.name = name
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id
    }
}
