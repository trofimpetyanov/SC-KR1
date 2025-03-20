import Foundation

struct ImportData {
    let accounts: [BankAccount]
    let categories: [Category]
    let operations: [Operation]
}

class DataImporter {
    
    func importData(from fileURL: URL) -> Result<ImportData, Error> {
        do {
            
            let data = try loadDataFromFile(fileURL)
            
            
            let parsedData = try parseData(data)
            
            
            let validatedData = try validateData(parsedData)
            
            
            let importData = try transformToImportData(validatedData)
            
            return .success(importData)
        } catch {
            return .failure(error)
        }
    }
    
    
    private func loadDataFromFile(_ fileURL: URL) throws -> Data {
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw ImportError.fileReadError(error.localizedDescription)
        }
    }
    
    
    func parseData(_ data: Data) throws -> Any {
        
        fatalError("Method must be overridden by subclasses")
    }
    
    
    func validateData(_ parsedData: Any) throws -> Any {
        
        guard let dict = parsedData as? [String: Any],
              let _ = dict["accounts"] as? [[String: Any]],
              let _ = dict["categories"] as? [[String: Any]],
              let _ = dict["operations"] as? [[String: Any]] else {
            throw ImportError.invalidDataStructure
        }
        
        return parsedData
    }
    
    
    func transformToImportData(_ validatedData: Any) throws -> ImportData {
        guard let dict = validatedData as? [String: Any],
              let accountsData = dict["accounts"] as? [[String: Any]],
              let categoriesData = dict["categories"] as? [[String: Any]],
              let operationsData = dict["operations"] as? [[String: Any]] else {
            throw ImportError.invalidDataStructure
        }
        
        var accounts: [BankAccount] = []
        var categories: [Category] = []
        var operations: [Operation] = []
        
        do {
            
            for accountDict in accountsData {
                guard let idString = accountDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = accountDict["name"] as? String,
                      let balance = accountDict["balance"] as? Double else {
                    throw ImportError.invalidAccountData
                }
                
                let account = BankAccount(id: id, name: name, balance: balance)
                accounts.append(account)
            }
            
            
            for categoryDict in categoriesData {
                guard let idString = categoryDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let typeString = categoryDict["type"] as? String,
                      let type = OperationType(rawValue: typeString),
                      let name = categoryDict["name"] as? String else {
                    throw ImportError.invalidCategoryData
                }
                
                let category = Category(id: id, type: type, name: name)
                categories.append(category)
            }
            
            
            for operationDict in operationsData {
                guard let idString = operationDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let typeString = operationDict["type"] as? String,
                      let type = OperationType(rawValue: typeString),
                      let bankAccountIdString = operationDict["bank_account_id"] as? String,
                      let bankAccountId = UUID(uuidString: bankAccountIdString),
                      let categoryIdString = operationDict["category_id"] as? String,
                      let categoryId = UUID(uuidString: categoryIdString),
                      let amount = operationDict["amount"] as? Double,
                      let dateString = operationDict["date"] as? String else {
                    throw ImportError.invalidOperationData
                }
                
                let dateFormatter = ISO8601DateFormatter()
                guard let date = dateFormatter.date(from: dateString) else {
                    throw ImportError.invalidDateFormat
                }
                
                let description = operationDict["description"] as? String
                
                let operation = Operation(id: id, type: type, bankAccountId: bankAccountId,
                                          categoryId: categoryId, amount: amount,
                                          date: date, description: description)
                operations.append(operation)
            }
            
            return ImportData(accounts: accounts, categories: categories, operations: operations)
        } catch {
            throw error
        }
    }
    
    
    enum ImportError: Error, LocalizedError {
        case fileReadError(String)
        case parseError(String)
        case invalidDataStructure
        case invalidAccountData
        case invalidCategoryData
        case invalidOperationData
        case invalidDateFormat
        
        var errorDescription: String? {
            switch self {
            case .fileReadError(let message):
                return "Ошибка чтения файла: \(message)"
            case .parseError(let message):
                return "Ошибка парсинга файла: \(message)"
            case .invalidDataStructure:
                return "Неверная структура данных в файле"
            case .invalidAccountData:
                return "Неверные данные счета"
            case .invalidCategoryData:
                return "Неверные данные категории"
            case .invalidOperationData:
                return "Неверные данные операции"
            case .invalidDateFormat:
                return "Неверный формат даты"
            }
        }
    }
}
