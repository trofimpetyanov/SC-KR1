import Foundation

class AccountRepository {
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
    
    func createAccount(name: String, initialBalance: Double = 0) -> Result<BankAccount, Error> {
        do {
            let account = try AccountFactory.create(name: name, initialBalance: initialBalance)
            print("AccountRepository: Created new account - ID: \(account.id), Name: \(account.name), Balance: \(account.balance)")
            
            
            dataStore.saveAccount(account)
            return .success(account)
        } catch {
            print("AccountRepository: Failed to create account - \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func updateAccount(id: UUID, name: String? = nil, balance: Double? = nil) -> Result<BankAccount, Error> {
        print("AccountRepository: Attempting to update account ID: \(id)")
        print("  - New name: \(name ?? "unchanged")")
        print("  - New balance: \(balance != nil ? String(balance!) : "unchanged")")
        
        guard let existingAccount = getAccount(withId: id) else {
            print("AccountRepository: Failed to find account with ID: \(id)")
            return .failure(NSError(domain: "AccountError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Account not found"]))
        }
        
        print("AccountRepository: Found account - ID: \(existingAccount.id), Current name: \(existingAccount.name), Current balance: \(existingAccount.balance)")
        
        do {
            
            let updatedAccount = try AccountFactory.update(account: existingAccount, name: name, balance: balance)
            print("AccountRepository: Updated account - ID: \(updatedAccount.id), New name: \(updatedAccount.name), New balance: \(updatedAccount.balance)")
            
            
            dataStore.saveAccount(updatedAccount)
            return .success(updatedAccount)
        } catch {
            print("AccountRepository: Failed to update account - \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func deleteAccount(withId id: UUID) -> Result<Void, Error> {
        print("AccountRepository: Attempting to delete account ID: \(id)")
        
        guard getAccount(withId: id) != nil else {
            print("AccountRepository: Failed to find account with ID: \(id)")
            return .failure(NSError(domain: "AccountError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Account not found"]))
        }
        
        let operations = dataStore.getOperations(forAccount: id)
        if !operations.isEmpty {
            print("AccountRepository: Cannot delete account ID: \(id) - it has \(operations.count) operations")
            return .failure(NSError(domain: "AccountError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot delete account with associated operations"]))
        }
        
        print("AccountRepository: Deleting account ID: \(id)")
        dataStore.deleteAccount(withId: id)
        return .success(())
    }
    
    
    
    func updateBalance(forAccountId id: UUID, amount: Double) -> Result<BankAccount, Error> {
        print("AccountRepository: Updating balance for account ID: \(id) by amount: \(amount)")
        
        guard let account = getAccount(withId: id) else {
            print("AccountRepository: Failed to find account with ID: \(id)")
            return .failure(NSError(domain: "AccountError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Account not found"]))
        }
        
        let newBalance = account.balance + amount
        print("AccountRepository: Changing balance from \(account.balance) to \(newBalance)")
        
        return updateAccount(id: id, balance: newBalance)
    }
}
