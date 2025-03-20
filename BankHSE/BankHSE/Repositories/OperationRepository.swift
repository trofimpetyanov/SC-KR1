import Foundation

class OperationRepository {
    private let dataStore: DataStore
    private let operationFactory: OperationFactory
    
    init(dataStore: DataStore, operationFactory: OperationFactory) {
        self.dataStore = dataStore
        self.operationFactory = operationFactory
    }
    
    func getAllOperations() -> [Operation] {
        return dataStore.getAllOperations()
    }
    
    func getOperations(forAccount accountId: UUID) -> [Operation] {
        return dataStore.getOperations(forAccount: accountId)
    }
    
    func getOperations(forCategory categoryId: UUID) -> [Operation] {
        return dataStore.getOperations(forCategory: categoryId)
    }
    
    func getOperations(ofType type: OperationType) -> [Operation] {
        return dataStore.getOperations(ofType: type)
    }
    
    func getOperations(inPeriod startDate: Date, endDate: Date) -> [Operation] {
        return dataStore.getOperations(inPeriod: startDate, endDate: endDate)
    }
    
    func getOperation(withId id: UUID) -> Operation? {
        return dataStore.getOperation(withId: id)
    }
    
    func createOperation(type: OperationType, bankAccountId: UUID, categoryId: UUID, 
                         amount: Double, date: Date = Date(), description: String? = nil) -> Result<Operation, Error> {
        
        let result = operationFactory.create(type: type, bankAccountId: bankAccountId, 
                                            categoryId: categoryId, amount: amount, 
                                            date: date, description: description)
        
        switch result {
        case .success(let operation):
            dataStore.saveOperation(operation)
            return .success(operation)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func updateOperation(id: UUID, categoryId: UUID? = nil, amount: Double? = nil, 
                         date: Date? = nil, description: String? = nil) -> Result<Operation, Error> {
        
        guard let operation = dataStore.getOperation(withId: id) else {
            return .failure(RepositoryError.operationNotFound)
        }
        
        let result = operationFactory.update(operation: operation, categoryId: categoryId, 
                                            amount: amount, date: date, description: description)
        
        switch result {
        case .success(let updatedOperation):
            dataStore.saveOperation(updatedOperation)
            return .success(updatedOperation)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func deleteOperation(withId id: UUID) -> Result<Void, Error> {
        guard let _ = dataStore.getOperation(withId: id) else {
            return .failure(RepositoryError.operationNotFound)
        }
        
        dataStore.deleteOperation(withId: id)
        return .success(())
    }
    
    
    
    func getIncomeExpenseDifference(inPeriod startDate: Date, endDate: Date) -> Double {
        let operations = dataStore.getOperations(inPeriod: startDate, endDate: endDate)
        
        var income: Double = 0
        var expense: Double = 0
        
        for operation in operations {
            switch operation.type {
            case .income:
                income += operation.amount
            case .expense:
                expense += operation.amount
            }
        }
        
        return income - expense
    }
    
    func getOperationsGroupedByCategory(inPeriod startDate: Date, endDate: Date) -> [UUID: Double] {
        let operations = dataStore.getOperations(inPeriod: startDate, endDate: endDate)
        
        var result: [UUID: Double] = [:]
        
        for operation in operations {
            let categoryId = operation.categoryId
            let amount = operation.amount
            
            if let existingAmount = result[categoryId] {
                result[categoryId] = existingAmount + amount
            } else {
                result[categoryId] = amount
            }
        }
        
        return result
    }
    
    enum RepositoryError: Error, LocalizedError {
        case operationNotFound
        
        var errorDescription: String? {
            switch self {
            case .operationNotFound:
                return "Операция не найдена"
            }
        }
    }
}
