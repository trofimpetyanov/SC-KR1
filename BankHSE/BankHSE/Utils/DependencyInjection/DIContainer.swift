import Foundation
import SwiftUI



class MainFacade {
    let accountsFacade: AccountsFacade
    let categoriesFacade: CategoriesFacade
    let operationsFacade: OperationsFacade
    let dataStore: DataStore
    
    init(accountsFacade: AccountsFacade, categoriesFacade: CategoriesFacade, operationsFacade: OperationsFacade, dataStore: DataStore) {
        self.accountsFacade = accountsFacade
        self.categoriesFacade = categoriesFacade
        self.operationsFacade = operationsFacade
        self.dataStore = dataStore
    }
}

class DIContainer {
    
    static let shared = DIContainer()
    
    
    
    private(set) var dataStore: DataStore
    private(set) var localDataStore: LocalDataStore
    private(set) var accountRepository: AccountRepository
    private(set) var categoryRepository: CategoryRepository
    private(set) var operationRepository: OperationRepository
    
    private(set) var accountsFacade: AccountsFacade
    private(set) var categoriesFacade: CategoriesFacade
    private(set) var operationsFacade: OperationsFacade
    private(set) var analyticsFacade: BankHSE.AnalyticsFacade
    
    private(set) var mainFacade: MainFacade
    
    
    private(set) var jsonImporter: JSONImporter
    private(set) var csvImporter: CSVImporter
    
    
    
    private init() {
        self.localDataStore = LocalDataStore()
        self.dataStore = DataStoreProxy(dataStore: self.localDataStore)
        
        self.accountRepository = AccountRepository(dataStore: dataStore)
        self.categoryRepository = CategoryRepository(dataStore: dataStore)
        
        let operationFactory = OperationFactory(dataStore: dataStore)
        self.operationRepository = OperationRepository(
            dataStore: dataStore,
            operationFactory: operationFactory
        )
        
        self.accountsFacade = AccountsFacade(accountRepository: accountRepository, diContainer: nil)
        self.categoriesFacade = CategoriesFacade(categoryRepository: categoryRepository, diContainer: nil)
        self.operationsFacade = OperationsFacade(operationRepository: operationRepository, diContainer: nil)
        self.analyticsFacade = BankHSE.AnalyticsFacade(operationRepository: operationRepository)
        
        self.mainFacade = MainFacade(
            accountsFacade: accountsFacade,
            categoriesFacade: categoriesFacade,
            operationsFacade: operationsFacade,
            dataStore: dataStore
        )
        
        self.jsonImporter = JSONImporter()
        self.csvImporter = CSVImporter()
        
        self.accountsFacade.setDIContainer(self)
        self.categoriesFacade.setDIContainer(self)
        self.operationsFacade.setDIContainer(self)
    }
    
    
    
    func notifyDataChanged() {
        print("DIContainer: Broadcasting data change notification")
        refreshDataStore()
        
        AppState.shared.forceRefresh()
    }
    
    func refreshDataStore() {
        print("DIContainer: Refreshing data store")
        
        if let proxy = dataStore as? DataStoreProxy {
            proxy.clearCache()
        }
        
        let accounts = dataStore.getAllAccounts()
        let categories = dataStore.getAllCategories()
        let operations = dataStore.getAllOperations()
        
        print("DIContainer: Refreshed - \(accounts.count) accounts, \(categories.count) categories, \(operations.count) operations")
    }
    
    
    
    
    func getAccountsFacade() -> AccountsFacade {
        return accountsFacade
    }
    
    func getCategoriesFacade() -> CategoriesFacade {
        return categoriesFacade
    }
    
    func getOperationsFacade() -> OperationsFacade {
        return operationsFacade
    }
    
    func getAnalyticsFacade() -> BankHSE.AnalyticsFacade {
        return analyticsFacade
    }
    
    
    func getLocalDataStore() -> LocalDataStore {
        return localDataStore
    }
    
    
    func getJSONImporter() -> JSONImporter {
        return jsonImporter
    }
    
    func getCSVImporter() -> CSVImporter {
        return csvImporter
    }
    
    
    
    
    func createAccountCommand(name: String, balance: Double = 0) -> CreateAccountCommand {
        return CreateAccountCommand(facade: accountsFacade, name: name, balance: balance)
    }
    
    func deleteAccountCommand(accountId: UUID) -> DeleteAccountCommand {
        return DeleteAccountCommand(facade: accountsFacade, accountId: accountId)
    }
    
    func updateAccountCommand(accountId: UUID, name: String? = nil, balance: Double? = nil) -> UpdateAccountCommand {
        return UpdateAccountCommand(facade: accountsFacade, accountId: accountId, name: name, balance: balance)
    }
    
    func recalculateAccountBalanceCommand(accountId: UUID) -> RecalculateAccountBalanceCommand {
        return RecalculateAccountBalanceCommand(facade: accountsFacade, accountId: accountId)
    }
    
    
    func createOperationCommand(type: OperationType, bankAccountId: UUID, categoryId: UUID, 
                                amount: Double, date: Date = Date(), description: String? = nil) -> CreateOperationCommand {
        return CreateOperationCommand(
            facade: operationsFacade,
            type: type,
            bankAccountId: bankAccountId,
            categoryId: categoryId,
            amount: amount,
            date: date,
            description: description
        )
    }
    
    func deleteOperationCommand(operationId: UUID) -> DeleteOperationCommand {
        return DeleteOperationCommand(facade: operationsFacade, operationId: operationId)
    }
    
    func updateOperationCommand(operationId: UUID, categoryId: UUID? = nil, 
                                amount: Double? = nil, date: Date? = nil, description: String? = nil) -> UpdateOperationCommand {
        return UpdateOperationCommand(
            facade: operationsFacade,
            operationId: operationId,
            categoryId: categoryId,
            amount: amount,
            date: date,
            description: description
        )
    }
    
    
    func getIncomeExpenseDifferenceCommand(startDate: Date, endDate: Date) -> GetIncomeExpenseDifferenceCommand {
        return GetIncomeExpenseDifferenceCommand(facade: analyticsFacade, startDate: startDate, endDate: endDate)
    }
    
    func getOperationsGroupedByCategoryCommand(startDate: Date, endDate: Date) -> GetOperationsGroupedByCategoryCommand {
        return GetOperationsGroupedByCategoryCommand(facade: analyticsFacade, startDate: startDate, endDate: endDate)
    }
    
    func getTopCategoriesCommand(type: OperationType, startDate: Date, endDate: Date, limit: Int = 5) -> GetTopCategoriesCommand {
        return GetTopCategoriesCommand(
            facade: analyticsFacade,
            type: type,
            startDate: startDate,
            endDate: endDate,
            limit: limit
        )
    }
    
    
    
    
    func withTimeMeasurement<T: Command>(_ command: T, commandName: String) -> TimeMeasurementDecorator<T> {
        return TimeMeasurementDecorator(wrappedCommand: command, commandName: commandName)
    }
    
    
    func withTimeMeasurement<T: VoidCommand>(_ command: T, commandName: String) -> VoidTimeMeasurementDecorator<T> {
        return VoidTimeMeasurementDecorator(wrappedCommand: command, commandName: commandName)
    }
}
