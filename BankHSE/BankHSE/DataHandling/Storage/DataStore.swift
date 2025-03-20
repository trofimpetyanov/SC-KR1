import Foundation

protocol DataStore {
    
    func getAllAccounts() -> [BankAccount]
    func getAccount(withId id: UUID) -> BankAccount?
    func saveAccount(_ account: BankAccount)
    func deleteAccount(withId id: UUID)
    
    
    func getAllCategories() -> [Category]
    func getCategories(ofType type: OperationType) -> [Category]
    func getCategory(withId id: UUID) -> Category?
    func saveCategory(_ category: Category)
    func deleteCategory(withId id: UUID)
    
    
    func getAllOperations() -> [Operation]
    func getOperations(forAccount accountId: UUID) -> [Operation]
    func getOperations(forCategory categoryId: UUID) -> [Operation]
    func getOperations(ofType type: OperationType) -> [Operation]
    func getOperations(inPeriod startDate: Date, endDate: Date) -> [Operation]
    func getOperation(withId id: UUID) -> Operation?
    func saveOperation(_ operation: Operation)
    func deleteOperation(withId id: UUID)
}
