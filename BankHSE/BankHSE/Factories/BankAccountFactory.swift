import Foundation

class BankAccountFactory {
    static func create(name: String, balance: Double = 0) -> Result<BankAccount, Error> {
        
        if name.isEmpty {
            return .failure(ValidationError.emptyName)
        }
        
        if name.count > 50 {
            return .failure(ValidationError.nameTooLong)
        }
        
        if balance < -1_000_000 || balance > 1_000_000_000 {
            return .failure(ValidationError.invalidBalance)
        }
        
        let account = BankAccount(name: name, balance: balance)
        return .success(account)
    }
    
    static func update(account: BankAccount, name: String? = nil, balance: Double? = nil) -> Result<BankAccount, Error> {
        var updatedName = account.name
        var updatedBalance = account.balance
        
        if let name = name {
            if name.isEmpty {
                return .failure(ValidationError.emptyName)
            }
            
            if name.count > 50 {
                return .failure(ValidationError.nameTooLong)
            }
            
            updatedName = name
        }
        
        if let balance = balance {
            if balance < -1_000_000 || balance > 1_000_000_000 {
                return .failure(ValidationError.invalidBalance)
            }
            
            updatedBalance = balance
        }
        
        let updatedAccount = BankAccount(id: account.id, name: updatedName, balance: updatedBalance)
        return .success(updatedAccount)
    }
    
    enum ValidationError: Error, LocalizedError {
        case emptyName
        case nameTooLong
        case invalidBalance
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Название счета не может быть пустым"
            case .nameTooLong:
                return "Название счета должно быть короче 50 символов"
            case .invalidBalance:
                return "Недопустимое значение баланса"
            }
        }
    }
}
