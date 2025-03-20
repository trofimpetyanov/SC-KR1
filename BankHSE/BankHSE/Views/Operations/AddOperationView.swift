import SwiftUI

struct AddOperationView: View {
    let type: OperationType
    let accounts: [BankAccount]
    let categories: [Category]
    let onAdd: (UUID, UUID, Double, Date, String?) -> Void
    
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var amountString = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private var isFormValid: Bool {
        selectedAccountId != nil && selectedCategoryId != nil && !amountString.isEmpty &&
        (Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация об операции")) {
                    HStack {
                        Text("Тип")
                        Spacer()
                        Text(type.displayName)
                            .foregroundColor(type == .income ? .green : .red)
                    }
                    
                    if accounts.isEmpty {
                        Text("Нет доступных счетов. Сначала создайте счет.")
                            .foregroundColor(.red)
                    } else {
                        Picker("Счет", selection: $selectedAccountId) {
                            Text("Выберите счет").tag(nil as UUID?)
                            ForEach(accounts) { account in
                                Text(account.name).tag(account.id as UUID?)
                            }
                        }
                    }
                    
                    if categories.isEmpty {
                        Text("Нет доступных категорий. Сначала создайте категорию.")
                            .foregroundColor(.red)
                    } else {
                        Picker("Категория", selection: $selectedCategoryId) {
                            Text("Выберите категорию").tag(nil as UUID?)
                            ForEach(categories) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                    }
                    
                    TextField("Сумма", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Дата", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Описание (необязательно)", text: $description)
                }
            }
            .navigationTitle("Новая операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        addOperation()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addOperation() {
        guard let accountId = selectedAccountId else {
            errorMessage = "Выберите счет"
            showingError = true
            return
        }
        
        guard let categoryId = selectedCategoryId else {
            errorMessage = "Выберите категорию"
            showingError = true
            return
        }
        
        guard let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            errorMessage = "Введите корректную сумму"
            showingError = true
            return
        }
        
        let finalDescription = description.isEmpty ? nil : description
        
        onAdd(accountId, categoryId, amount, date, finalDescription)
    }
} 