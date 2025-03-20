import Foundation

class CreateOperationCommand: Command {
    typealias Result = Operation
    
    private let facade: OperationsFacade
    private let type: OperationType
    private let bankAccountId: UUID
    private let categoryId: UUID
    private let amount: Double
    private let date: Date
    private let description: String?
    
    init(facade: OperationsFacade, type: OperationType, bankAccountId: UUID, categoryId: UUID, 
         amount: Double, date: Date = Date(), description: String? = nil) {
        self.facade = facade
        self.type = type
        self.bankAccountId = bankAccountId
        self.categoryId = categoryId
        self.amount = amount
        self.date = date
        self.description = description
    }
    
    func execute() -> Operation {
        let result = facade.createOperation(
            type: type,
            bankAccountId: bankAccountId,
            categoryId: categoryId,
            amount: amount,
            date: date,
            description: description
        )
        
        switch result {
        case .success(let operation):
            return operation
        case .failure(let error):
            fatalError("Ошибка создания операции: \(error.localizedDescription)")
        }
    }
}

class DeleteOperationCommand: VoidCommand {
    private let facade: OperationsFacade
    private let operationId: UUID
    
    init(facade: OperationsFacade, operationId: UUID) {
        self.facade = facade
        self.operationId = operationId
    }
    
    func execute() {
        let result = facade.deleteOperation(withId: operationId)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            fatalError("Ошибка удаления операции: \(error.localizedDescription)")
        }
    }
}

class UpdateOperationCommand: Command {
    typealias Result = Operation
    
    private let facade: OperationsFacade
    private let operationId: UUID
    private let categoryId: UUID?
    private let amount: Double?
    private let date: Date?
    private let description: String?
    
    init(facade: OperationsFacade, operationId: UUID, categoryId: UUID? = nil, 
         amount: Double? = nil, date: Date? = nil, description: String? = nil) {
        self.facade = facade
        self.operationId = operationId
        self.categoryId = categoryId
        self.amount = amount
        self.date = date
        self.description = description
    }
    
    func execute() -> Operation {
        let result = facade.updateOperation(
            id: operationId,
            categoryId: categoryId,
            amount: amount,
            date: date,
            description: description
        )
        
        switch result {
        case .success(let operation):
            return operation
        case .failure(let error):
            fatalError("Ошибка обновления операции: \(error.localizedDescription)")
        }
    }
}

class GetIncomeExpenseDifferenceCommand: Command {
    typealias Result = Double
    
    private let facade: BankHSE.AnalyticsFacade
    private let startDate: Date
    private let endDate: Date
    
    init(facade: BankHSE.AnalyticsFacade, startDate: Date, endDate: Date) {
        self.facade = facade
        self.startDate = startDate
        self.endDate = endDate
    }
    
    func execute() -> Double {
        return facade.getIncomeExpenseDifference(inPeriod: startDate, endDate: endDate)
    }
}

class GetOperationsGroupedByCategoryCommand: Command {
    typealias Result = [UUID: Double]
    
    private let facade: BankHSE.AnalyticsFacade
    private let startDate: Date
    private let endDate: Date
    
    init(facade: BankHSE.AnalyticsFacade, startDate: Date, endDate: Date) {
        self.facade = facade
        self.startDate = startDate
        self.endDate = endDate
    }
    
    func execute() -> [UUID: Double] {
        return facade.getOperationsGroupedByCategory(inPeriod: startDate, endDate: endDate)
    }
}

class GetTopCategoriesCommand: Command {
    typealias Result = [(UUID, Double)]
    
    private let facade: BankHSE.AnalyticsFacade
    private let type: OperationType
    private let startDate: Date
    private let endDate: Date
    private let limit: Int
    
    init(facade: BankHSE.AnalyticsFacade, type: OperationType, startDate: Date, endDate: Date, limit: Int = 5) {
        self.facade = facade
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.limit = limit
    }
    
    func execute() -> [(UUID, Double)] {
        return facade.getTopCategories(ofType: type, inPeriod: startDate, endDate: endDate, limit: limit)
    }
}
