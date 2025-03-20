import Foundation
import Yams
import UIKit
import UniformTypeIdentifiers

enum DataFormat: String, CaseIterable, Identifiable {
    case yaml = "YAML"
    case json = "JSON"
    case csv = "CSV"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .yaml: return "yaml"
        case .json: return "json"
        case .csv: return "csv"
        }
    }

    var mimeType: String {
        switch self {
        case .yaml: return "application/x-yaml"
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }

    var utType: UTType {
        switch self {
        case .yaml: return UTType.yaml
        case .json: return UTType.json
        case .csv: return UTType.commaSeparatedText
        }
    }
}

extension UTType {
    static var yaml: UTType {
        UTType(importedAs: "public.yaml")
    }
}

struct BankData: Codable {
    var accounts: [BankAccount]
    var categories: [Category]
    var operations: [Operation]
}

enum ExportImportError: Error {
    case serializationFailed
    case deserializationFailed
    case fileOperationFailed
    case unsupportedFormat
    case documentPickerCancelled
}

protocol ExportImportService {
    func exportData() -> Result<URL, Error>
    func importData(from url: URL) -> Result<Void, Error>
    func getExportedFiles() -> [URL]
}

class DataExportImportService {
    static let shared = DataExportImportService()

    private let fileManager = FileManager.default
    private let mainFacade: MainFacade

    init(mainFacade: MainFacade = DIContainer.shared.mainFacade) {
        self.mainFacade = mainFacade
    }



    func exportData(format: DataFormat, to directory: URL? = nil) -> Result<URL, Error> {
        let data = BankData(
            accounts: mainFacade.accountsFacade.getAllAccounts(),
            categories: mainFacade.categoriesFacade.getAllCategories(),
            operations: mainFacade.operationsFacade.getAllOperations()
        )

        do {
            let (serialized, fileExtension) = try serializeData(data, format: format)


            let baseDirectory = directory ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = "bankdata_\(dateFormatter.string(from: Date())).\(fileExtension)"
            var fileURL = baseDirectory.appendingPathComponent(fileName)

            try serialized.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Data Export: Data exported to \(fileURL.path) in \(format.rawValue) format")


            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try fileURL.setResourceValues(resourceValues)

            return .success(fileURL)
        } catch {
            print("Data Export Error: \(error.localizedDescription)")
            return .failure(error)
        }
    }



    func importData(from url: URL) -> Result<Void, Error> {
        var coordinationError: NSError?
        var importResult: Result<Void, Error>?

        NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinationError) { (coordinatedURL) in
            do {
                let fileContent = try String(contentsOf: coordinatedURL, encoding: .utf8)
                let format = determineFormat(from: coordinatedURL)
                let data = try deserializeData(fileContent, format: format)


                let dataStore = mainFacade.dataStore


                clearAllData()


                for account in data.accounts {
                    dataStore.saveAccount(account)
                }


                for category in data.categories {
                    dataStore.saveCategory(category)
                }


                for operation in data.operations {
                    dataStore.saveOperation(operation)
                }


                AppState.shared.forceRefresh()

                print("Data Import: Successfully imported data from \(coordinatedURL.path)")
                importResult = .success(())
            } catch {
                print("Data Import Error: \(error.localizedDescription)")
                importResult = .failure(error)
            }

            url.stopAccessingSecurityScopedResource()
        }

        if let coordinationError = coordinationError {
            return .failure(coordinationError)
        }

        return importResult ?? .failure(ExportImportError.fileOperationFailed)
    }



    private func determineFormat(from url: URL) -> DataFormat {
        let fileExtension = url.pathExtension.lowercased()

        if fileExtension == "yaml" || fileExtension == "yml" {
            return .yaml
        } else if fileExtension == "json" {
            return .json
        } else if fileExtension == "csv" {
            return .csv
        } else {

            return .json
        }
    }

    private func serializeData(_ data: BankData, format: DataFormat) throws -> (String, String) {
        switch format {
        case .yaml:
            let encoder = YAMLEncoder()
            let yamlString = try encoder.encode(data)
            return (yamlString, "yaml")

        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return (jsonString, "json")
            } else {
                throw ExportImportError.serializationFailed
            }

        case .csv:
            let csvString = createCSVExport(data: data)
            return (csvString, "csv")
        }
    }

    private func deserializeData(_ content: String, format: DataFormat) throws -> BankData {
        switch format {
        case .yaml:
            let decoder = YAMLDecoder()
            return try decoder.decode(BankData.self, from: content)

        case .json:
            let decoder = JSONDecoder()
            guard let data = content.data(using: .utf8) else {
                throw ExportImportError.deserializationFailed
            }
            return try decoder.decode(BankData.self, from: data)

        case .csv:
            return try parseCSVData(content)
        }
    }

    private func clearAllData() {
        let dataStore = mainFacade.dataStore

        for operation in dataStore.getAllOperations() {
            dataStore.deleteOperation(withId: operation.id)
        }

        for account in dataStore.getAllAccounts() {
            dataStore.deleteAccount(withId: account.id)
        }

        for category in dataStore.getAllCategories() {
            dataStore.deleteCategory(withId: category.id)
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()


    func getExportedFiles(format: DataFormat? = nil) -> [URL] {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)

            if let format = format {

                return files.filter { $0.pathExtension.lowercased() == format.fileExtension.lowercased() }
                    .sorted { $0.lastPathComponent > $1.lastPathComponent }
            } else {

                return files.filter {
                    let ext = $0.pathExtension.lowercased()
                    return ext == "yaml" || ext == "yml" || ext == "json" || ext == "csv"
                }.sorted { $0.lastPathComponent > $1.lastPathComponent }
            }
        } catch {
            print("Error finding files: \(error)")
            return []
        }
    }


    private func createCSVExport(data: BankData) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var csv = "BANK_HSE_EXPORT\n\n"

        csv += "ACCOUNTS\n"
        csv += "ID,Name,Balance\n"
        for account in data.accounts {
            csv += "\(account.id.uuidString),\"\(account.name)\",\(account.balance)\n"
        }
        csv += "\n"

        csv += "CATEGORIES\n"
        csv += "ID,Type,Name\n"
        for category in data.categories {
            csv += "\(category.id.uuidString),\(category.type.rawValue),\"\(category.name)\"\n"
        }
        csv += "\n"

        csv += "OPERATIONS\n"
        csv += "ID,Type,BankAccountID,CategoryID,Amount,Date,Description\n"
        for operation in data.operations {
            let description = operation.description?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            csv += "\(operation.id.uuidString),\(operation.type.rawValue),\(operation.bankAccountId.uuidString),\(operation.categoryId.uuidString),\(operation.amount),\"\(dateFormatter.string(from: operation.date))\",\"\(description)\"\n"
        }

        return csv
    }


    private func parseCSVData(_ csvContent: String) throws -> BankData {
        let lines = csvContent.components(separatedBy: .newlines)

        var accounts: [BankAccount] = []
        var categories: [Category] = []
        var operations: [Operation] = []

        var section = ""

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.isEmpty {
                continue
            }

            if trimmedLine == "ACCOUNTS" {
                section = "ACCOUNTS"
                continue
            } else if trimmedLine == "CATEGORIES" {
                section = "CATEGORIES"
                continue
            } else if trimmedLine == "OPERATIONS" {
                section = "OPERATIONS"
                continue
            } else if trimmedLine == "BANK_HSE_EXPORT" {

                continue
            }

            if trimmedLine.starts(with: "ID,") {
                continue
            }

            let values = parseCSVLine(trimmedLine)
            if values.count < 3 {
                continue
            }

            switch section {
            case "ACCOUNTS":
                if values.count >= 3,
                   let id = UUID(uuidString: values[0]),
                   let balance = Double(values[2]) {
                    let account = BankAccount(id: id, name: values[1], balance: balance)
                    accounts.append(account)
                }

            case "CATEGORIES":
                if values.count >= 3,
                   let id = UUID(uuidString: values[0]),
                   let type = OperationType(rawValue: values[1]) {
                    let category = Category(id: id, type: type, name: values[2])
                    categories.append(category)
                }

            case "OPERATIONS":
                if values.count >= 6,
                   let id = UUID(uuidString: values[0]),
                   let type = OperationType(rawValue: values[1]),
                   let bankAccountId = UUID(uuidString: values[2]),
                   let categoryId = UUID(uuidString: values[3]),
                   let amount = Double(values[4]) {

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short

                    if let date = dateFormatter.date(from: values[5]) {
                        let description = values.count > 6 ? values[6] : nil
                        let operation = Operation(id: id, type: type, bankAccountId: bankAccountId, categoryId: categoryId, amount: amount, date: date, description: description)
                        operations.append(operation)
                    }
                }

            default:
                break
            }
        }

        return BankData(accounts: accounts, categories: categories, operations: operations)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes = !insideQuotes
            } else if char == "," && !insideQuotes {
                result.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }

        result.append(currentValue)
        return result
    }
}

typealias YAMLExportImport = DataExportImportService
