import SwiftUI

class CategoriesViewModel: ObservableObject {
    @Published var categories: [Category] = []
    let facade: CategoriesFacade
    
    init(facade: CategoriesFacade) {
        self.facade = facade
    }
    
    func loadCategories(selectedType: OperationType) {
        let allCategories = facade.getAllCategories()
        print("CategoriesView: Loaded \(allCategories.count) categories from facade")
        
        let filteredCategories = allCategories.filter { $0.type == selectedType }
        print("CategoriesView: Filtered to \(filteredCategories.count) categories of type \(selectedType)")
        
        for category in filteredCategories {
            print("CategoriesView: Category - ID: \(category.id), Name: \(category.name), Type: \(category.type)")
        }
        
        categories = filteredCategories
    }
}

struct CategoriesView: View {
    @StateObject private var viewModel: CategoriesViewModel
    @ObservedObject private var appState = AppState.shared
    @State private var selectedType: OperationType = .expense
    @State private var showingAddCategory = false
    @State private var showingEditCategory = false
    @State private var categoryToEdit: Category?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let facade: CategoriesFacade
    
    init(facade: CategoriesFacade) {
        self.facade = facade
        self._viewModel = StateObject(wrappedValue: CategoriesViewModel(facade: facade))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if filteredCategories.isEmpty {
                        ContentUnavailableView {
                            Label(
                                selectedType == .expense ? "Нет категорий расходов" : "Нет категорий доходов",
                                systemImage: "tag.slash"
                            )
                        } description: {
                            Text("Добавьте новую категорию нажав на '+' вверху экрана")
                        }
                    } else {
                        ForEach(filteredCategories) { category in
                            CategoryRow(category: category)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    categoryToEdit = category
                                    showingEditCategory = true
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteCategory(category)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: {
                    Picker("Тип категории", selection: $selectedType) {
                        Text("Расходы").tag(OperationType.expense)
                        Text("Доходы").tag(OperationType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .textCase(nil)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(.init())
                    .padding(.vertical)
                    .onChange(of: selectedType) { oldValue, newValue in
                        loadCategories()
                    }
                }
            }
            .navigationTitle("Категории")
            .listStyle(InsetGroupedListStyle())
            .refreshable {
                loadCategories()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory, onDismiss: {
                loadCategories()
            }) {
                AddCategoryView(type: selectedType) { name in
                    addCategory(name: name, type: selectedType)
                    showingAddCategory = false
                }
            }
            .onChange(of: showingAddCategory) { oldValue, newValue in
                if !newValue {
                    loadCategories()
                    AppState.shared.forceRefresh()
                }
            }
            .sheet(item: $categoryToEdit, onDismiss: {
                loadCategories()
            }) { category in
                EditCategoryView(
                    category: category,
                    onSave: { name in
                        updateCategory(category: category, newName: name)
                        categoryToEdit = nil
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            loadCategories()
                            AppState.shared.forceRefresh()
                        }
                    },
                    onDelete: {
                        deleteCategory(category)
                        categoryToEdit = nil
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            loadCategories()
                            AppState.shared.forceRefresh()
                        }
                    }
                )
            }
            .onChange(of: categoryToEdit) { oldValue, newValue in
                if newValue == nil {
                    loadCategories()
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
            loadCategories()
            
            
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
            loadCategories()
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: .dataDidChange, object: nil)
    }
    
    private var filteredCategories: [Category] {
        return viewModel.categories.filter { $0.type == selectedType }
    }
    
    private func loadCategories() {
        viewModel.loadCategories(selectedType: selectedType)
    }
    
    private func addCategory(name: String, type: OperationType) {
        let result = facade.createCategory(name: name, type: type)
        
        switch result {
        case .success:
            loadCategories()
            
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func updateCategory(category: Category, newName: String) {
        print("CategoriesView: Updating category ID: \(category.id), Current name: \(category.name), New name: \(newName)")
        
        let result = facade.updateCategory(id: category.id, name: newName)
        
        switch result {
        case .success(let updatedCategory):
            print("CategoriesView: Category updated successfully - New name: \(updatedCategory.name)")
            
            loadCategories()
        case .failure(let error):
            print("CategoriesView: Failed to update category - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func deleteCategory(_ category: Category) {
        print("Attempting to delete category: \(category.id) - \(category.name)")
        let result = facade.deleteCategory(withId: category.id)
        let currentSelectedType = selectedType
        
        switch result {
        case .success:
            print("Category deleted successfully")
            
            DispatchQueue.main.async {
                
                self.selectedType = currentSelectedType
                
                self.viewModel.loadCategories(selectedType: currentSelectedType)
                
                AppState.shared.forceRefresh()
            }
        case .failure(let error):
            print("Failed to delete category: \(error.localizedDescription)")
            errorMessage = "Не удалось удалить категорию: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    private func deleteCategoryAtOffsets(offsets: IndexSet) {
        let categoriesToDelete = offsets.map { filteredCategories[$0] }
        for category in categoriesToDelete {
            deleteCategory(category)
        }
    }
}

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(category.name)
                    .font(.headline)
                Text(category.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(category.type == .income ? .green : .red)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct AddCategoryView: View {
    @State private var name = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    let type: OperationType
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о категории")) {
                    TextField("Название категории", text: $name)
                    
                    HStack {
                        Text("Тип")
                        Spacer()
                        Text(type.displayName)
                            .foregroundColor(type == .income ? .green : .red)
                    }
                }
            }
            .navigationTitle("Новая категория")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        addCategory()
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
    
    private func addCategory() {
        if name.isEmpty {
            errorMessage = "Введите название категории"
            showingError = true
            return
        }
        
        onAdd(name)
    }
}

struct EditCategoryView: View {
    let category: Category
    let onSave: (String) -> Void
    let onDelete: () -> Void
    
    @State private var name: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(category: Category, onSave: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        self.category = category
        self.onSave = onSave
        self.onDelete = onDelete
        self._name = State(initialValue: category.name)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о категории")) {
                    TextField("Название категории", text: $name)
                    
                    HStack {
                        Text("Тип")
                        Spacer()
                        Text(category.type.displayName)
                            .foregroundColor(category.type == .income ? .green : .red)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Удалить категорию", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Изменение категории")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty || name == category.name)
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Удалить категорию?", isPresented: $showingDeleteAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("Вы уверены, что хотите удалить эту категорию? Все связанные операции будут затронуты.")
            }
        }
    }
    
    private func saveCategory() {
        if name.isEmpty {
            errorMessage = "Введите название категории"
            showingError = true
            return
        }
        
        onSave(name)
    }
}

#Preview {
    let dataStore = DataStoreProxy(dataStore: LocalDataStore())
    let categoryRepository = CategoryRepository(dataStore: dataStore)
    let facade = CategoriesFacade(categoryRepository: categoryRepository)
    
    return CategoriesView(facade: facade)
}
