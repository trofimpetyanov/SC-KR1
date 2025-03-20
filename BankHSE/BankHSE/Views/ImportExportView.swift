import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var importFormat: DataFormat = .json
    @State private var exportFormat: DataFormat = .json
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private let container = DIContainer.shared

    enum DataFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"

        var id: String { self.rawValue }

        var utType: UTType {
            switch self {
            case .json: return .json
            case .csv: return .commaSeparatedText
            }
        }

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Импорт данных")) {
                Picker("Формат файла", selection: $importFormat) {
                    ForEach(DataFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }

                Button("Импортировать данные") {
                    isImporting = true
                }

                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)

                    Text("Импорт данных заменит все существующие данные приложения.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Экспорт данных")) {
                Picker("Формат файла", selection: $exportFormat) {
                    ForEach(DataFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }

                Button("Экспортировать данные") {
                    exportData()
                }
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {

                if alertTitle == "Успешно" && alertMessage.contains("импортированы") {
                    NotificationCenter.default.post(name: .dataDidChange, object: nil)
                }
            }
        } message: {
            Text(alertMessage)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [importFormat.utType],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: ExportDocument(data: exportedData(), format: exportFormat),
            contentType: exportFormat.utType,
            defaultFilename: "bank_data.\(exportFormat.fileExtension)"
        ) { result in
            handleExportResult(result)
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else {
                showAlert(title: "Ошибка", message: "Файл не выбран")
                return
            }

            if !selectedFile.startAccessingSecurityScopedResource() {
                showAlert(title: "Ошибка", message: "Нет доступа к выбранному файлу")
                return
            }

            defer { selectedFile.stopAccessingSecurityScopedResource() }

            let importer: DataImporter

            switch importFormat {
            case .json:
                importer = container.getJSONImporter()
            case .csv:
                importer = container.getCSVImporter()
            }

            let importResult = importer.importData(from: selectedFile)

            switch importResult {
            case .success(let importData):

                saveImportedData(importData)
                showAlert(title: "Успешно", message: "Данные успешно импортированы")
            case .failure(let error):
                showAlert(title: "Ошибка", message: "Не удалось импортировать данные: \(error.localizedDescription)")
            }

        } catch {
            showAlert(title: "Ошибка", message: "Не удалось обработать файл: \(error.localizedDescription)")
        }
    }

    private func saveImportedData(_ data: BankHSE.ImportData) {
        let dataStore = container.getLocalDataStore()

        let allAccounts = dataStore.getAllAccounts()
        for account in allAccounts {
            dataStore.deleteAccount(withId: account.id)
        }

        let allCategories = dataStore.getAllCategories()
        for category in allCategories {
            dataStore.deleteCategory(withId: category.id)
        }

        let allOperations = dataStore.getAllOperations()
        for operation in allOperations {
            dataStore.deleteOperation(withId: operation.id)
        }

        for account in data.accounts {
            dataStore.saveAccount(account)
        }

        for category in data.categories {
            dataStore.saveCategory(category)
        }

        for operation in data.operations {
            dataStore.saveOperation(operation)
        }
    }

    private func exportData() {
        isExporting = true
    }

    private func exportedData() -> String {
        let dataStore = container.getLocalDataStore()

        let accounts = dataStore.getAllAccounts()
        let categories = dataStore.getAllCategories()
        let operations = dataStore.getAllOperations()

        switch exportFormat {
        case .json:
            return createJSONExport(accounts: accounts, categories: categories, operations: operations)
        case .csv:
            return createCSVExport(accounts: accounts, categories: categories, operations: operations)
        }
    }

    private func createJSONExport(accounts: [BankAccount], categories: [Category], operations: [Operation]) -> String {
        let dateFormatter = ISO8601DateFormatter()

        var json: [String: Any] = [:]

        var accountsArray: [[String: Any]] = []
        for account in accounts {
            let accountDict: [String: Any] = [
                "id": account.id.uuidString,
                "name": account.name,
                "balance": account.balance
            ]
            accountsArray.append(accountDict)
        }
        json["accounts"] = accountsArray

        var categoriesArray: [[String: Any]] = []
        for category in categories {
            let categoryDict: [String: Any] = [
                "id": category.id.uuidString,
                "type": category.type.rawValue,
                "name": category.name
            ]
            categoriesArray.append(categoryDict)
        }
        json["categories"] = categoriesArray

        var operationsArray: [[String: Any]] = []
        for operation in operations {
            var operationDict: [String: Any] = [
                "id": operation.id.uuidString,
                "type": operation.type.rawValue,
                "bank_account_id": operation.bankAccountId.uuidString,
                "category_id": operation.categoryId.uuidString,
                "amount": operation.amount,
                "date": dateFormatter.string(from: operation.date)
            ]

            if let description = operation.description {
                operationDict["description"] = description
            }

            operationsArray.append(operationDict)
        }
        json["operations"] = operationsArray

        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "{}"
    }

    private func createCSVExport(accounts: [BankAccount], categories: [Category], operations: [Operation]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var csv = "BANK_HSE_EXPORT\n\n"

        csv += "ACCOUNTS\n"
        csv += "ID,Name,Balance\n"
        for account in accounts {
            csv += "\(account.id.uuidString),\"\(account.name)\",\(account.balance)\n"
        }
        csv += "\n"

        csv += "CATEGORIES\n"
        csv += "ID,Type,Name\n"
        for category in categories {
            csv += "\(category.id.uuidString),\(category.type.rawValue),\"\(category.name)\"\n"
        }
        csv += "\n"

        csv += "OPERATIONS\n"
        csv += "ID,Type,BankAccountID,CategoryID,Amount,Date,Description\n"
        for operation in operations {
            let description = operation.description?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            csv += "\(operation.id.uuidString),\(operation.type.rawValue),\(operation.bankAccountId.uuidString),\(operation.categoryId.uuidString),\(operation.amount),\"\(dateFormatter.string(from: operation.date))\",\"\(description)\"\n"
        }

        return csv
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(_):
            showAlert(title: "Успешно", message: "Данные успешно экспортированы в файл")
        case .failure(let error):
            showAlert(title: "Ошибка", message: "Не удалось экспортировать данные: \(error.localizedDescription)")
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json, .commaSeparatedText]

    var data: String
    var format: ImportExportView.DataFormat

    init(data: String, format: ImportExportView.DataFormat) {
        self.data = data
        self.format = format
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = String(decoding: data, as: UTF8.self)
        self.format = .json
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(data.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
