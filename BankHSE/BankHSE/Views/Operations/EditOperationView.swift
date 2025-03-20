import SwiftUI

struct EditOperationView: View {
    let operation: Operation
    let accounts: [BankAccount]
    let categories: [Category]
    let onSave: (UUID, Double, Date, String?) -> Void
    let onDelete: () -> Void
    
    @State private var selectedCategoryId: UUID
    @State private var amountString: String
    @State private var date: Date
    @State private var description: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(operation: Operation, accounts: [BankAccount], categories: [Category], onSave: @escaping (UUID, Double, Date, String?) -> Void, onDelete: @escaping () -> Void) {
        self.operation = operation
        self.accounts = accounts
        self.categories = categories
        self.onSave = onSave
        self.onDelete = onDelete
        
        self._selectedCategoryId = State(initialValue: operation.categoryId)
        self._amountString = State(initialValue: String(format: "%.2f", operation.amount))
        self._date = State(initialValue: operation.date)
        self._description = State(initialValue: operation.description ?? "")
    }
    
    private var isFormValid: Bool {
        !amountString.isEmpty && (Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    
    private var isFormChanged: Bool {
        selectedCategoryId != operation.categoryId ||
        amountString != String(format: "%.2f", operation.amount) ||
        date != operation.date ||
        description != (operation.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация об операции")) {
                    HStack {
                        Text("Тип")
                        Spacer()
                        Text(operation.type.displayName)
                            .foregroundColor(operation.type == .income ? .green : .red)
                    }
                    
                    HStack {
                        Text("Счет")
                        Spacer()
                        Text(accounts.first { $0.id == operation.bankAccountId }?.name ?? "Неизвестный счет")
                            .foregroundColor(.secondary)
                    }
                    
                    if categories.isEmpty {
                        Text("Нет доступных категорий.")
                            .foregroundColor(.red)
                    } else {
                        Picker("Категория", selection: $selectedCategoryId) {
                            ForEach(categories) { category in
                                Text(category.name).tag(category.id)
                            }
                        }
                    }
                    
                    TextField("Сумма", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Дата", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Описание (необязательно)", text: $description)
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Удалить операцию", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Изменение операции")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveOperation()
                    }
                    .disabled(!isFormValid || !isFormChanged)
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Удалить операцию?", isPresented: $showingDeleteConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("Вы уверены, что хотите удалить эту операцию?")
            }
        }
    }
    
    private func saveOperation() {
        guard let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            errorMessage = "Введите корректную сумму"
            showingError = true
            return
        }
        
        let finalDescription = description.isEmpty ? nil : description
        
        onSave(selectedCategoryId, amount, date, finalDescription)
    }
} 