import SwiftUI

class AccountsViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    let facade: AccountsFacade
    
    init(facade: AccountsFacade) {
        self.facade = facade
    }
    
    func loadAccounts() {
        let allAccounts = facade.getAllAccounts()
        print("AccountsView: Loaded \(allAccounts.count) accounts from facade")
        
        for account in allAccounts {
            print("AccountsView: Account - ID: \(account.id), Name: \(account.name), Balance: \(account.balance)")
        }
        
        accounts = allAccounts
    }
}

struct AccountsView: View {
    @StateObject private var viewModel: AccountsViewModel
    @ObservedObject private var appState = AppState.shared
    @State private var showingAddAccount = false
    @State private var showingEditAccount = false
    @State private var accountToEdit: BankAccount?
    @State private var showingDeleteConfirmation = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let facade: AccountsFacade
    
    init(facade: AccountsFacade) {
        self.facade = facade
        self._viewModel = StateObject(wrappedValue: AccountsViewModel(facade: facade))
    }
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.accounts.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("Нет созданных счетов", systemImage: "creditcard.slash")
                        } description: {
                            Text("Добавьте новый счет нажав на '+' вверху экрана")
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color(.systemGroupedBackground))
                    }
                } else {
                    ForEach(viewModel.accounts) { account in
                        AccountRow(account: account)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                accountToEdit = account
                                showingEditAccount = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteAccount(account)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .refreshable {
                viewModel.loadAccounts()
            }
            .navigationTitle("Счета")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAccount = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount, onDismiss: {
                viewModel.loadAccounts()
            }) {
                AddAccountView { name, balance in
                    addAccount(name: name, balance: balance)
                    showingAddAccount = false
                }
            }
            .onChange(of: showingAddAccount) { _, newValue in
                if !newValue {
                    viewModel.loadAccounts()
                    AppState.shared.forceRefresh()
                }
            }
            .sheet(item: $accountToEdit, onDismiss: {
                viewModel.loadAccounts()
            }) { account in
                EditAccountView(
                    account: account, 
                    onSave: { name, balance in
                        updateAccount(account: account, newName: name, newBalance: balance)
                        accountToEdit = nil
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.loadAccounts()
                            AppState.shared.forceRefresh()
                        }
                    },
                    onDelete: {
                        deleteAccount(account)
                        accountToEdit = nil
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.loadAccounts()
                            AppState.shared.forceRefresh()
                        }
                    }
                )
            }
            .onChange(of: accountToEdit) { _, newValue in
                if newValue == nil {
                    viewModel.loadAccounts()
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
            
            viewModel.loadAccounts()
            
            
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
            viewModel.loadAccounts()
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: .dataDidChange, object: nil)
    }
    
    private func addAccount(name: String, balance: Double) {
        let result = facade.createAccount(name: name, balance: balance)
        
        switch result {
        case .success:
            viewModel.loadAccounts()
            
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func updateAccount(account: BankAccount, newName: String, newBalance: Double) {
        print("AccountsView: Updating account ID: \(account.id), Current name: \(account.name), New name: \(newName)")
        
        let result = facade.updateAccount(id: account.id, name: newName, balance: newBalance)
        
        switch result {
        case .success(let updatedAccount):
            print("AccountsView: Account updated successfully - New name: \(updatedAccount.name)")
            
            viewModel.loadAccounts()
        case .failure(let error):
            print("AccountsView: Failed to update account - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func deleteAccount(_ account: BankAccount) {
        let result = facade.deleteAccount(withId: account.id)
        
        switch result {
        case .success:
            viewModel.loadAccounts()
            
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
}

struct AccountRow: View {
    let account: BankAccount
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.headline)
                Text("Баланс: \(account.balance.formattedAsCurrency())")
                    .font(.subheadline)
                    .foregroundColor(account.balance >= 0 ? .green : .red)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct AddAccountView: View {
    @State private var name = ""
    @State private var balanceString = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (String, Double) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о счете")) {
                    TextField("Название счета", text: $name)
                    TextField("Начальный баланс", text: $balanceString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Новый счет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        addAccount()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addAccount() {
        
        let balance: Double
        if balanceString.isEmpty {
            balance = 0
        } else if let value = Double(balanceString.replacingOccurrences(of: ",", with: ".")) {
            balance = value
        } else {
            errorMessage = "Введите корректное значение баланса"
            showingError = true
            return
        }
        
        onAdd(name, balance)
    }
}

struct EditAccountView: View {
    let account: BankAccount
    let onSave: (String, Double) -> Void
    let onDelete: () -> Void
    
    @State private var name: String
    @State private var balanceString: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    init(account: BankAccount, onSave: @escaping (String, Double) -> Void, onDelete: @escaping () -> Void) {
        self.account = account
        self.onSave = onSave
        self.onDelete = onDelete
        self._name = State(initialValue: account.name)
        self._balanceString = State(initialValue: String(format: "%.2f", account.balance))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о счете")) {
                    TextField("Название счета", text: $name)
                    TextField("Баланс", text: $balanceString)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Удалить счет", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Изменение счета")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveAccount()
                    }
                    .disabled(name.isEmpty || name == account.name && balanceString == String(format: "%.2f", account.balance))
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Удалить счет?", isPresented: $showingDeleteConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("Вы уверены, что хотите удалить этот счет? Все связанные операции будут затронуты.")
            }
        }
    }
    
    private func saveAccount() {
        guard !name.isEmpty else {
            errorMessage = "Введите название счета"
            showingError = true
            return
        }
        
        let balance: Double
        if balanceString.isEmpty {
            balance = 0
        } else if let value = Double(balanceString.replacingOccurrences(of: ",", with: ".")) {
            balance = value
        } else {
            errorMessage = "Введите корректное значение баланса"
            showingError = true
            return
        }
        
        onSave(name, balance)
    }
}

#Preview {
    let dataStore = DataStoreProxy(dataStore: LocalDataStore())
    let accountRepository = AccountRepository(dataStore: dataStore)
    let facade = AccountsFacade(accountRepository: accountRepository)
    
    return AccountsView(facade: facade)
}
