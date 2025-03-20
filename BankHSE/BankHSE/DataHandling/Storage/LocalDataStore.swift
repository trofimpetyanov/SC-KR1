import Foundation

class LocalDataStore: DataStore {
    
    enum Keys: String {
        case accounts = "bank_accounts"
        case categories = "categories"
        case operations = "operations"
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        if getAllAccounts().isEmpty {
            createDefaultData()
        }
    }
    
    private func createDefaultData() {
        let defaultAccount = BankAccount(name: "Основной счет")
        saveAccount(defaultAccount)
        
        let incomeCategories = [
            Category(id: UUID(), type: .income, name: "Зарплата"),
            Category(id: UUID(), type: .income, name: "Подарок"),
            Category(id: UUID(), type: .income, name: "Кэшбэк")
        ]
        
        let expenseCategories = [
            Category(id: UUID(), type: .expense, name: "Продукты"),
            Category(id: UUID(), type: .expense, name: "Транспорт"),
            Category(id: UUID(), type: .expense, name: "Развлечения"),
            Category(id: UUID(), type: .expense, name: "Здоровье")
        ]
        
        incomeCategories.forEach { saveCategory($0) }
        expenseCategories.forEach { saveCategory($0) }
    }
    
    private func saveData<T: Encodable>(_ data: [T], forKey key: String) {
        do {
            let data = try JSONEncoder().encode(data)
            defaults.set(data, forKey: key)
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }
    
    private func loadData<T: Decodable>(forKey key: String, as type: T.Type) -> [T] {
        guard let data = defaults.data(forKey: key) else { return [] }
        
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("Error loading data: \(error.localizedDescription)")
            return []
        }
    }
    
    func getAllAccounts() -> [BankAccount] {
        return loadData(forKey: Keys.accounts.rawValue, as: BankAccount.self)
    }
    
    func getAccount(withId id: UUID) -> BankAccount? {
        return getAllAccounts().first { $0.id == id }
    }
    
    func saveAccount(_ account: BankAccount) {
        print("LocalDataStore: Saving account - ID: \(account.id), Name: \(account.name), Balance: \(account.balance)")
        
        var accounts = getAllAccounts()
        
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            
            print("LocalDataStore: Replacing existing account at index \(index)")
            accounts[index] = account
        } else {
            
            print("LocalDataStore: Adding new account")
            accounts.append(account)
        }
        
        if let encoded = try? JSONEncoder().encode(accounts) {
            print("LocalDataStore: Saving \(accounts.count) accounts to UserDefaults")
            UserDefaults.standard.set(encoded, forKey: Keys.accounts.rawValue)
            
            
            let savedAccounts = getAllAccounts()
            if let savedAccount = savedAccounts.first(where: { $0.id == account.id }) {
                print("LocalDataStore: Account saved successfully - ID: \(savedAccount.id), Name: \(savedAccount.name), Balance: \(savedAccount.balance)")
            } else {
                print("LocalDataStore: ERROR - Account not saved properly")
            }
        }
    }
    
    func deleteAccount(withId id: UUID) {
        let accounts = getAllAccounts().filter { $0.id != id }
        saveData(accounts, forKey: Keys.accounts.rawValue)
    }
    
    func getAllCategories() -> [Category] {
        return loadData(forKey: Keys.categories.rawValue, as: Category.self)
    }
    
    func getCategories(ofType type: OperationType) -> [Category] {
        return getAllCategories().filter { $0.type == type }
    }
    
    func getCategory(withId id: UUID) -> Category? {
        return getAllCategories().first { $0.id == id }
    }
    
    func saveCategory(_ category: Category) {
        print("LocalDataStore: Saving category - ID: \(category.id), Name: \(category.name), Type: \(category.type)")
        
        var categories = getAllCategories()
        
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            
            print("LocalDataStore: Replacing existing category at index \(index)")
            categories[index] = category
        } else {
            
            print("LocalDataStore: Adding new category")
            categories.append(category)
        }
        
        if let encoded = try? JSONEncoder().encode(categories) {
            print("LocalDataStore: Saving \(categories.count) categories to UserDefaults")
            UserDefaults.standard.set(encoded, forKey: Keys.categories.rawValue)
            
            
            let savedCategories = getAllCategories()
            if let savedCategory = savedCategories.first(where: { $0.id == category.id }) {
                print("LocalDataStore: Category saved successfully - ID: \(savedCategory.id), Name: \(savedCategory.name), Type: \(savedCategory.type)")
            } else {
                print("LocalDataStore: ERROR - Category not saved properly")
            }
        }
    }
    
    func deleteCategory(withId id: UUID) {
        let categories = getAllCategories().filter { $0.id != id }
        saveData(categories, forKey: Keys.categories.rawValue)
    }
    
    func getAllOperations() -> [Operation] {
        return loadData(forKey: Keys.operations.rawValue, as: Operation.self)
    }
    
    func getOperations(forAccount accountId: UUID) -> [Operation] {
        return getAllOperations().filter { $0.bankAccountId == accountId }
    }
    
    func getOperations(forCategory categoryId: UUID) -> [Operation] {
        return getAllOperations().filter { $0.categoryId == categoryId }
    }
    
    func getOperations(ofType type: OperationType) -> [Operation] {
        return getAllOperations().filter { $0.type == type }
    }
    
    func getOperations(inPeriod startDate: Date, endDate: Date) -> [Operation] {
        return getAllOperations().filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    func getOperation(withId id: UUID) -> Operation? {
        return getAllOperations().first { $0.id == id }
    }
    
    func saveOperation(_ operation: Operation) {
        var operations = getAllOperations()
        let isNew = !operations.contains(where: { $0.id == operation.id })
        
        if let index = operations.firstIndex(where: { $0.id == operation.id }) {
            let oldOperation = operations[index]
            
            if isNew {
                updateAccountBalance(for: operation)
            } else {
                reverseAccountBalance(for: oldOperation)
                updateAccountBalance(for: operation)
            }
            
            operations[index] = operation
        } else {
            operations.append(operation)
            updateAccountBalance(for: operation)
        }
        
        saveData(operations, forKey: Keys.operations.rawValue)
    }
    
    func deleteOperation(withId id: UUID) {
        guard let operation = getOperation(withId: id) else { return }
        
        let operations = getAllOperations().filter { $0.id != id }
        saveData(operations, forKey: Keys.operations.rawValue)
        
        reverseAccountBalance(for: operation)
    }
    
    private func updateAccountBalance(for operation: Operation) {
        guard let account = getAccount(withId: operation.bankAccountId) else { return }
        
        var updatedAccount = account
        
        switch operation.type {
        case .income:
            updatedAccount.balance += operation.amount
        case .expense:
            updatedAccount.balance -= operation.amount
        }
        
        saveAccount(updatedAccount)
    }
    
    private func reverseAccountBalance(for operation: Operation) {
        guard let account = getAccount(withId: operation.bankAccountId) else { return }
        
        var updatedAccount = account
        
        switch operation.type {
        case .income:
            updatedAccount.balance -= operation.amount
        case .expense:
            updatedAccount.balance += operation.amount
        }
        
        saveAccount(updatedAccount)
    }
}
