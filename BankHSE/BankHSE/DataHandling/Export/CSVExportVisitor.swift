import Foundation

class CSVExportVisitor: StringExportVisitor {
    override func visit(bankAccount: BankAccount) -> String {
        let headers = ["id", "name", "balance"]
        let values = [bankAccount.id.uuidString, bankAccount.name, String(bankAccount.balance)]
        
        return headers.joined(separator: ",") + "\n" + values.joined(separator: ",")
    }
    
    override func visit(category: Category) -> String {
        let headers = ["id", "type", "name"]
        let values = [category.id.uuidString, category.type.rawValue, category.name]
        
        return headers.joined(separator: ",") + "\n" + values.joined(separator: ",")
    }
    
    override func visit(operation: Operation) -> String {
        let headers = ["id", "type", "bank_account_id", "category_id", "amount", "date", "description"]
        
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: operation.date)
        
        var values = [
            operation.id.uuidString,
            operation.type.rawValue,
            operation.bankAccountId.uuidString,
            operation.categoryId.uuidString,
            String(operation.amount),
            dateString
        ]
        
        if let description = operation.description {
            values.append(description)
        } else {
            values.append("")
        }
        
        return headers.joined(separator: ",") + "\n" + values.joined(separator: ",")
    }
    
    override func exportAllData(accounts: [BankAccount], categories: [Category], operations: [Operation]) -> String {
        var result = ""
        
        result += "# accounts\n"
        result += "id,name,balance\n"
        
        for account in accounts {
            let values = [
                account.id.uuidString,
                account.name,
                String(account.balance)
            ]
            result += values.joined(separator: ",") + "\n"
        }
        
        result += "\n"
        
        result += "# categories\n"
        result += "id,type,name\n"
        
        for category in categories {
            let values = [
                category.id.uuidString,
                category.type.rawValue,
                category.name
            ]
            result += values.joined(separator: ",") + "\n"
        }
        
        result += "\n"
        
        result += "# operations\n"
        result += "id,type,bank_account_id,category_id,amount,date,description\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for operation in operations {
            let dateString = dateFormatter.string(from: operation.date)
            
            var values = [
                operation.id.uuidString,
                operation.type.rawValue,
                operation.bankAccountId.uuidString,
                operation.categoryId.uuidString,
                String(operation.amount),
                dateString
            ]
            
            if let description = operation.description {
                values.append(escapeCSVField(description))
            } else {
                values.append("")
            }
            
            result += values.joined(separator: ",") + "\n"
        }
        
        return result
    }
    
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        return field
    }
}
