import Foundation

class AccountsFacade {
    private let accountRepository: AccountRepository
    private var diContainer: DIContainer?
    
    init(accountRepository: AccountRepository, diContainer: DIContainer? = DIContainer.shared) {
        self.accountRepository = accountRepository
        self.diContainer = diContainer
    }
    
    
    func setDIContainer(_ container: DIContainer) {
        self.diContainer = container
    }
    
    
    
    func getAllAccounts() -> [BankAccount] {
        return accountRepository.getAllAccounts()
    }
    
    func getAccount(withId id: UUID) -> BankAccount? {
        return accountRepository.getAccount(withId: id)
    }
    
    func createAccount(name: String, balance: Double = 0) -> Result<BankAccount, Error> {
        let result = accountRepository.createAccount(name: name, initialBalance: balance)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func updateAccount(id: UUID, name: String? = nil, balance: Double? = nil) -> Result<BankAccount, Error> {
        let result = accountRepository.updateAccount(id: id, name: name, balance: balance)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func deleteAccount(withId id: UUID) -> Result<Void, Error> {
        let result = accountRepository.deleteAccount(withId: id)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func recalculateBalance(forAccountId id: UUID) -> Result<BankAccount, Error> {
        let result = accountRepository.updateBalance(forAccountId: id, amount: 0)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
}
