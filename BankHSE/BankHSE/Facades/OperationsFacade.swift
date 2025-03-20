import Foundation

class OperationsFacade {
    private let operationRepository: OperationRepository
    private var diContainer: DIContainer?
    
    init(operationRepository: OperationRepository, diContainer: DIContainer? = DIContainer.shared) {
        self.operationRepository = operationRepository
        self.diContainer = diContainer
    }
    
    
    func setDIContainer(_ container: DIContainer) {
        self.diContainer = container
    }
    
    
    
    func getAllOperations() -> [Operation] {
        return operationRepository.getAllOperations()
    }
    
    func getOperations(forAccount accountId: UUID) -> [Operation] {
        return operationRepository.getOperations(forAccount: accountId)
    }
    
    func getOperations(forCategory categoryId: UUID) -> [Operation] {
        return operationRepository.getOperations(forCategory: categoryId)
    }
    
    func getOperations(ofType type: OperationType) -> [Operation] {
        return operationRepository.getOperations(ofType: type)
    }
    
    func getOperations(inPeriod startDate: Date, endDate: Date) -> [Operation] {
        return operationRepository.getOperations(inPeriod: startDate, endDate: endDate)
    }
    
    func getOperation(withId id: UUID) -> Operation? {
        return operationRepository.getOperation(withId: id)
    }
    
    func createOperation(type: OperationType, bankAccountId: UUID, categoryId: UUID, 
                         amount: Double, date: Date = Date(), description: String? = nil) -> Result<Operation, Error> {
        let result = operationRepository.createOperation(type: type, bankAccountId: bankAccountId, categoryId: categoryId,
                                                        amount: amount, date: date, description: description)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func updateOperation(id: UUID, categoryId: UUID? = nil, amount: Double? = nil, 
                         date: Date? = nil, description: String? = nil) -> Result<Operation, Error> {
        let result = operationRepository.updateOperation(id: id, categoryId: categoryId, amount: amount,
                                                    date: date, description: description)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func deleteOperation(withId id: UUID) -> Result<Void, Error> {
        let result = operationRepository.deleteOperation(withId: id)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
}
