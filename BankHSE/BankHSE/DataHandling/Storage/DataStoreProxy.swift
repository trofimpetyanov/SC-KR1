import Foundation
import SwiftUI

class DataStoreProxy: DataStore {
    private let dataStore: DataStore
    
    
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    
    
    func getAllAccounts() -> [BankAccount] {
        
        return dataStore.getAllAccounts()
    }
    
    func getAccount(withId id: UUID) -> BankAccount? {
        return dataStore.getAccount(withId: id)
    }
    
    func saveAccount(_ account: BankAccount) {
        print("DataStoreProxy: Saving account ID: \(account.id), Name: \(account.name)")
        dataStore.saveAccount(account)
        
        forceRefreshUI()
    }
    
    func deleteAccount(withId id: UUID) {
        print("DataStoreProxy: Deleting account ID: \(id)")
        dataStore.deleteAccount(withId: id)
        
        forceRefreshUI()
    }
    
    
    
    func getAllCategories() -> [Category] {
        
        return dataStore.getAllCategories()
    }
    
    func getCategories(ofType type: OperationType) -> [Category] {
        return dataStore.getCategories(ofType: type)
    }
    
    func getCategory(withId id: UUID) -> Category? {
        return dataStore.getCategory(withId: id)
    }
    
    func saveCategory(_ category: Category) {
        print("DataStoreProxy: Saving category ID: \(category.id), Name: \(category.name)")
        dataStore.saveCategory(category)
        
        forceRefreshUI()
    }
    
    func deleteCategory(withId id: UUID) {
        print("DataStoreProxy: Deleting category ID: \(id)")
        dataStore.deleteCategory(withId: id)
        
        forceRefreshUI()
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
    
    func saveOperation(_ operation: Operation) {
        print("DataStoreProxy: Saving operation ID: \(operation.id)")
        dataStore.saveOperation(operation)
        
        forceRefreshUI()
    }
    
    func deleteOperation(withId id: UUID) {
        print("DataStoreProxy: Deleting operation ID: \(id)")
        dataStore.deleteOperation(withId: id)
        
        forceRefreshUI()
    }
    
    
    
    func clearCache() {
        
        print("DataStoreProxy: Cache cleared (no-op)")
    }
    
    
    
    private func forceRefreshUI() {
        
        NotificationCenter.default.post(name: .dataDidChange, object: nil)
        
        AppState.shared.forceRefresh()
    }
}
