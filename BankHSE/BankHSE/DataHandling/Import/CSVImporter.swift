import Foundation

class CSVImporter: DataImporter {
    override func parseData(_ data: Data) throws -> Any {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.parseError("Не удалось преобразовать данные в UTF-8 строку")
        }
        
        var result: [String: [[String: Any]]] = [
            "accounts": [],
            "categories": [],
            "operations": []
        ]
        
        let lines = csvString.components(separatedBy: .newlines)
        if lines.isEmpty {
            throw ImportError.parseError("CSV файл пуст")
        }
        
        var currentSection: String?
        var headers: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                
                continue
            }
            
            
            if trimmedLine.starts(with: "#") {
                let sectionName = trimmedLine.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                if ["accounts", "categories", "operations"].contains(sectionName) {
                    currentSection = sectionName
                    headers = [] 
                }
                continue
            }
            
            
            guard let section = currentSection else {
                continue
            }
            
            
            let cells = parseCSVLine(trimmedLine)
            
            
            if headers.isEmpty {
                headers = cells
                continue
            }
            
            
            var rowDict: [String: Any] = [:]
            for (index, header) in headers.enumerated() {
                if index < cells.count {
                    let value = cells[index]
                    
                    
                    if let doubleValue = Double(value) {
                        rowDict[header] = doubleValue
                    } else if value.lowercased() == "true" {
                        rowDict[header] = true
                    } else if value.lowercased() == "false" {
                        rowDict[header] = false
                    } else {
                        rowDict[header] = value
                    }
                }
            }
            
            
            result[section]?.append(rowDict)
        }
        
        return result
    }
    
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes = !insideQuotes
            } else if char == "," && !insideQuotes {
                result.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        if !currentValue.isEmpty {
            result.append(currentValue.trimmingCharacters(in: .whitespaces))
        }
        
        return result
    }
    
    
    override func validateData(_ parsedData: Any) throws -> Any {
        guard let dict = parsedData as? [String: [[String: Any]]],
              let accounts = dict["accounts"],
              let categories = dict["categories"],
              let operations = dict["operations"] else {
            throw ImportError.invalidDataStructure
        }
        
        for account in accounts {
            guard let _ = account["id"],
                  let _ = account["name"],
                  let _ = account["balance"] else {
                throw ImportError.invalidAccountData
            }
        }
        
        for category in categories {
            guard let _ = category["id"],
                  let _ = category["type"],
                  let _ = category["name"] else {
                throw ImportError.invalidCategoryData
            }
        }
        
        for operation in operations {
            guard let _ = operation["id"],
                  let _ = operation["type"],
                  let _ = operation["bank_account_id"],
                  let _ = operation["category_id"],
                  let _ = operation["amount"],
                  let _ = operation["date"] else {
                throw ImportError.invalidOperationData
            }
        }
        
        return parsedData
    }
}
