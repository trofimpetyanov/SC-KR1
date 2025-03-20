import Foundation

class CreateAccountCommand: Command {
    typealias Result = BankAccount
    
    private let facade: AccountsFacade
    private let name: String
    private let balance: Double
    
    init(facade: AccountsFacade, name: String, balance: Double = 0) {
        self.facade = facade
        self.name = name
        self.balance = balance
    }
    
    func execute() -> BankAccount {
        let result = facade.createAccount(name: name, balance: balance)
        
        switch result {
        case .success(let account):
            return account
        case .failure(let error):
            fatalError("Ошибка создания счета: \(error.localizedDescription)")
        }
    }
}

class DeleteAccountCommand: VoidCommand {
    private let facade: AccountsFacade
    private let accountId: UUID
    
    init(facade: AccountsFacade, accountId: UUID) {
        self.facade = facade
        self.accountId = accountId
    }
    
    func execute() {
        let result = facade.deleteAccount(withId: accountId)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            fatalError("Ошибка удаления счета: \(error.localizedDescription)")
        }
    }
}

class UpdateAccountCommand: Command {
    typealias Result = BankAccount
    
    private let facade: AccountsFacade
    private let accountId: UUID
    private let name: String?
    private let balance: Double?
    
    init(facade: AccountsFacade, accountId: UUID, name: String? = nil, balance: Double? = nil) {
        self.facade = facade
        self.accountId = accountId
        self.name = name
        self.balance = balance
    }
    
    func execute() -> BankAccount {
        let result = facade.updateAccount(id: accountId, name: name, balance: balance)
        
        switch result {
        case .success(let account):
            return account
        case .failure(let error):
            fatalError("Ошибка обновления счета: \(error.localizedDescription)")
        }
    }
}

class RecalculateAccountBalanceCommand: Command {
    typealias Result = BankAccount
    
    private let facade: AccountsFacade
    private let accountId: UUID
    
    init(facade: AccountsFacade, accountId: UUID) {
        self.facade = facade
        self.accountId = accountId
    }
    
    func execute() -> BankAccount {
        let result = facade.recalculateBalance(forAccountId: accountId)
        
        switch result {
        case .success(let account):
            return account
        case .failure(let error):
            fatalError("Ошибка пересчета баланса счета: \(error.localizedDescription)")
        }
    }
}
