import Foundation

class JSONExportVisitor: StringExportVisitor {
    override func visit(bankAccount: BankAccount) -> String {
        guard let data = try? JSONEncoder().encode(bankAccount),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        
        return jsonString
    }
    
    override func visit(category: Category) -> String {
        guard let data = try? JSONEncoder().encode(category),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        
        return jsonString
    }
    
    override func visit(operation: Operation) -> String {
        guard let data = try? JSONEncoder().encode(operation),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        
        return jsonString
    }
    
    override func exportAllData(accounts: [BankAccount], categories: [Category], operations: [Operation]) -> String {
        let exportDict: [String: Any] = [
            "accounts": accounts,
            "categories": categories,
            "operations": operations
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Ошибка при экспорте данных в JSON: \(error.localizedDescription)")
        }
        
        return "{}"
    }
}
