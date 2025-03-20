import Foundation

class OperationFactory {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    func create(type: OperationType, bankAccountId: UUID, categoryId: UUID, 
                amount: Double, date: Date = Date(), description: String? = nil) -> Result<Operation, Error> {
        
        if amount <= 0 {
            return .failure(ValidationError.nonPositiveAmount)
        }
        
        guard let _ = dataStore.getAccount(withId: bankAccountId) else {
            return .failure(ValidationError.accountNotFound)
        }
        
        guard let category = dataStore.getCategory(withId: categoryId) else {
            return .failure(ValidationError.categoryNotFound)
        }
        
        if category.type != type {
            return .failure(ValidationError.typeMismatch)
        }
        
        let operation = Operation(type: type, bankAccountId: bankAccountId, categoryId: categoryId, 
                                  amount: amount, date: date, description: description)
        return .success(operation)
    }
    
    func update(operation: Operation, categoryId: UUID? = nil, amount: Double? = nil, 
                date: Date? = nil, description: String? = nil) -> Result<Operation, Error> {
        
        var updatedCategoryId = operation.categoryId
        var updatedAmount = operation.amount
        var updatedDate = operation.date
        var updatedDescription = operation.description
        
        if let categoryId = categoryId {
            guard let category = dataStore.getCategory(withId: categoryId) else {
                return .failure(ValidationError.categoryNotFound)
            }
            
            if category.type != operation.type {
                return .failure(ValidationError.typeMismatch)
            }
            
            updatedCategoryId = categoryId
        }
        
        if let amount = amount {
            if amount <= 0 {
                return .failure(ValidationError.nonPositiveAmount)
            }
            
            updatedAmount = amount
        }
        
        if let date = date {
            updatedDate = date
        }
        
        updatedDescription = description
        
        let updatedOperation = Operation(id: operation.id, type: operation.type, 
                                         bankAccountId: operation.bankAccountId, 
                                         categoryId: updatedCategoryId, 
                                         amount: updatedAmount, 
                                         date: updatedDate, 
                                         description: updatedDescription)
        return .success(updatedOperation)
    }
    
    enum ValidationError: Error, LocalizedError {
        case nonPositiveAmount
        case accountNotFound
        case categoryNotFound
        case typeMismatch
        
        var errorDescription: String? {
            switch self {
            case .nonPositiveAmount:
                return "Сумма операции должна быть положительной"
            case .accountNotFound:
                return "Счет не найден"
            case .categoryNotFound:
                return "Категория не найдена"
            case .typeMismatch:
                return "Тип операции не соответствует типу категории"
            }
        }
    }
}
