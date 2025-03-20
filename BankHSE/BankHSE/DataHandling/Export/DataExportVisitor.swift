import Foundation

protocol DataExportVisitor {
    associatedtype Result
    
    
    func visit(bankAccount: BankAccount) -> Result
    func visit(category: Category) -> Result
    func visit(operation: Operation) -> Result
    
    
    func exportAllData(accounts: [BankAccount], categories: [Category], operations: [Operation]) -> Result
}

class StringExportVisitor: DataExportVisitor {
    typealias Result = String
    
    func visit(bankAccount: BankAccount) -> String {
        fatalError("Метод должен быть переопределен в подклассах")
    }
    
    func visit(category: Category) -> String {
        fatalError("Метод должен быть переопределен в подклассах")
    }
    
    func visit(operation: Operation) -> String {
        fatalError("Метод должен быть переопределен в подклассах")
    }
    
    func exportAllData(accounts: [BankAccount], categories: [Category], operations: [Operation]) -> String {
        fatalError("Метод должен быть переопределен в подклассах")
    }
}

extension BankAccount {
    func accept<V: DataExportVisitor>(_ visitor: V) -> V.Result {
        return visitor.visit(bankAccount: self)
    }
}

extension Category {
    func accept<V: DataExportVisitor>(_ visitor: V) -> V.Result {
        return visitor.visit(category: self)
    }
}

extension Operation {
    func accept<V: DataExportVisitor>(_ visitor: V) -> V.Result {
        return visitor.visit(operation: self)
    }
}
