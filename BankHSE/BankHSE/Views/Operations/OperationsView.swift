import SwiftUI

class OperationsViewModel: ObservableObject {
    @Published var operations: [Operation] = []
    @Published var accounts: [BankAccount] = []
    @Published var categories: [Category] = []
    
    let facade: OperationsFacade
    let accountsFacade: AccountsFacade
    let categoriesFacade: CategoriesFacade
    
    init(facade: OperationsFacade, accountsFacade: AccountsFacade, categoriesFacade: CategoriesFacade) {
        self.facade = facade
        self.accountsFacade = accountsFacade
        self.categoriesFacade = categoriesFacade
    }
    
    func loadData(selectedType: OperationType) {
        print("OperationsView: Loading data...")
        
        operations = facade.getAllOperations()
        print("OperationsView: Loaded \(operations.count) operations")
        
        accounts = accountsFacade.getAllAccounts()
        print("OperationsView: Loaded \(accounts.count) accounts")
        
        categories = categoriesFacade.getAllCategories()
        let filteredCategories = categories.filter { $0.type == selectedType }
        print("OperationsView: Loaded \(categories.count) categories, \(filteredCategories.count) match selected type")
    }
}

struct OperationsView: View {
    @StateObject private var viewModel: OperationsViewModel
    @ObservedObject private var appState = AppState.shared
    @State private var selectedType: OperationType = .expense
    @State private var showingAddOperation = false
    @State private var showingEditOperation = false
    @State private var operationToEdit: Operation?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let facade: OperationsFacade
    private let accountsFacade: AccountsFacade
    private let categoriesFacade: CategoriesFacade
    
    init(facade: OperationsFacade, accountsFacade: AccountsFacade, categoriesFacade: CategoriesFacade) {
        self.facade = facade
        self.accountsFacade = accountsFacade
        self.categoriesFacade = categoriesFacade
        self._viewModel = StateObject(wrappedValue: OperationsViewModel(facade: facade, accountsFacade: accountsFacade, categoriesFacade: categoriesFacade))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if filteredOperations.isEmpty {
                        ContentUnavailableView {
                            Label(
                                selectedType == .expense ? "Нет расходов" : "Нет доходов",
                                systemImage: "tray"
                            )
                        } description: {
                            Text("Добавьте новую операцию нажав на '+' вверху экрана")
                        }
                    } else {
                        ForEach(filteredOperations) { operation in
                            OperationRow(
                                operation: operation,
                                accountName: getAccountName(for: operation.bankAccountId),
                                categoryName: getCategoryName(for: operation.categoryId)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                operationToEdit = operation
                                showingEditOperation = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteOperation(operation)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Picker("Тип операции", selection: $selectedType) {
                        Text("Расходы").tag(OperationType.expense)
                        Text("Доходы").tag(OperationType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .textCase(nil)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(.init())
                    .padding(.vertical)
                    .onChange(of: selectedType) { oldValue, newValue in
                        loadData()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .refreshable {
                loadData()
            }
            .navigationTitle("Операции")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddOperation = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.accounts.isEmpty || viewModel.categories.filter { $0.type == selectedType }.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddOperation, onDismiss: {
                loadData()
            }) {
                AddOperationView(
                    type: selectedType,
                    accounts: viewModel.accounts,
                    categories: viewModel.categories.filter { $0.type == selectedType },
                    onAdd: { accountId, categoryId, amount, date, description in
                        addOperation(
                            type: selectedType,
                            accountId: accountId,
                            categoryId: categoryId,
                            amount: amount,
                            date: date,
                            description: description
                        )
                        showingAddOperation = false
                    }
                )
            }
            .onChange(of: showingAddOperation) { oldValue, newValue in
                if !newValue {
                    loadData()
                    AppState.shared.forceRefresh()
                }
            }
            .sheet(item: $operationToEdit, onDismiss: {
                loadData()
            }) { operation in
                EditOperationView(
                    operation: operation,
                    accounts: viewModel.accounts,
                    categories: viewModel.categories.filter { $0.type == operation.type },
                    onSave: { categoryId, amount, date, description in
                        updateOperation(
                            operation: operation,
                            categoryId: categoryId,
                            amount: amount,
                            date: date,
                            description: description
                        )
                        operationToEdit = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            loadData()
                            AppState.shared.forceRefresh()
                        }
                    },
                    onDelete: {
                        deleteOperation(operation)
                        operationToEdit = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            loadData()
                            AppState.shared.forceRefresh()
                        }
                    }
                )
            }
            .onChange(of: operationToEdit) { oldValue, newValue in
                if newValue == nil {
                    loadData()
                }
            }
            .alert("Ошибка", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .forceRefreshable()
        .onAppear {
            loadData()
            setupNotificationObserver()
        }
        .onDisappear {
            removeNotificationObserver()
        }
    }
    
    
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .dataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            loadData()
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: .dataDidChange, object: nil)
    }
    
    
    
    private var filteredOperations: [Operation] {
        return viewModel.operations
            .filter { $0.type == selectedType }
            .sorted { $0.date > $1.date }
    }
    
    private func loadData() {
        viewModel.loadData(selectedType: selectedType)
    }
    
    private func getAccountName(for id: UUID) -> String {
        return viewModel.accounts.first { $0.id == id }?.name ?? "Неизвестный счет"
    }
    
    private func getCategoryName(for id: UUID) -> String {
        return viewModel.categories.first { $0.id == id }?.name ?? "Неизвестная категория"
    }
    
    
    
    private func addOperation(type: OperationType, accountId: UUID, categoryId: UUID, amount: Double, date: Date, description: String?) {
        let result = facade.createOperation(
            type: type,
            bankAccountId: accountId,
            categoryId: categoryId,
            amount: amount,
            date: date,
            description: description
        )
        
        switch result {
        case .success:
            loadData()
            AppState.shared.forceRefresh()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func updateOperation(operation: Operation, categoryId: UUID, amount: Double, date: Date, description: String?) {
        let result = facade.updateOperation(
            id: operation.id,
            categoryId: categoryId,
            amount: amount,
            date: date,
            description: description
        )
        
        switch result {
        case .success:
            loadData()
            AppState.shared.forceRefresh()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func deleteOperation(_ operation: Operation) {
        let result = facade.deleteOperation(withId: operation.id)
        let currentSelectedType = selectedType
        
        switch result {
        case .success:
            DispatchQueue.main.async {
                self.selectedType = currentSelectedType
                self.viewModel.loadData(selectedType: currentSelectedType)
                AppState.shared.forceRefresh()
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
} 
