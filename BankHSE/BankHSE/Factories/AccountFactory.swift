import Foundation

class AccountFactory {
    
    static func create(name: String, initialBalance: Double = 0) throws -> BankAccount {
        if name.isEmpty {
            throw NSError(domain: "AccountValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Account name cannot be empty"])
        }
        
        if name.count > 30 {
            throw NSError(domain: "AccountValidationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Account name cannot exceed 30 characters"])
        }
        
        let account = BankAccount(id: UUID(), name: name, balance: initialBalance)
        return account
    }
    
    static func update(account: BankAccount, name: String? = nil, balance: Double? = nil) throws -> BankAccount {
        var updatedName = account.name
        var updatedBalance = account.balance
        
        if let name = name {
            if name.isEmpty {
                throw NSError(domain: "AccountValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Account name cannot be empty"])
            }
            
            if name.count > 30 {
                throw NSError(domain: "AccountValidationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Account name cannot exceed 30 characters"])
            }
            
            updatedName = name
        }
        
        if let balance = balance {
            updatedBalance = balance
        }
        
        print("AccountFactory: Creating new BankAccount instance for ID: \(account.id)")
        print("  - Name: \(account.name) -> \(updatedName)")
        print("  - Balance: \(account.balance) -> \(updatedBalance)")
        
        let updatedAccount = BankAccount(id: account.id, name: updatedName, balance: updatedBalance)
        return updatedAccount
    }
} 
