import Foundation

class CategoryRepository {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    
    
    func getAllCategories() -> [Category] {
        return dataStore.getAllCategories()
    }
    
    func getCategories(ofType type: OperationType) -> [Category] {
        return dataStore.getCategories(ofType: type)
    }
    
    func getCategory(withId id: UUID) -> Category? {
        return dataStore.getCategory(withId: id)
    }
    
    func createCategory(name: String, type: OperationType) -> Result<Category, Error> {
        do {
            let category = try CategoryFactory.create(name: name, type: type)
            print("CategoryRepository: Created new category - ID: \(category.id), Name: \(category.name), Type: \(category.type)")
            
            
            dataStore.saveCategory(category)
            return .success(category)
        } catch {
            print("CategoryRepository: Failed to create category - \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func updateCategory(id: UUID, name: String) -> Result<Category, Error> {
        print("CategoryRepository: Attempting to update category ID: \(id) with name: \(name)")
        
        guard let existingCategory = getCategory(withId: id) else {
            print("CategoryRepository: Failed to find category with ID: \(id)")
            return .failure(NSError(domain: "CategoryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Category not found"]))
        }
        
        print("CategoryRepository: Found category - ID: \(existingCategory.id), Current name: \(existingCategory.name)")
        
        do {
            
            let updatedCategory = try CategoryFactory.update(category: existingCategory, name: name)
            print("CategoryRepository: Updated category - ID: \(updatedCategory.id), New name: \(updatedCategory.name)")
            
            
            dataStore.saveCategory(updatedCategory)
            return .success(updatedCategory)
        } catch {
            print("CategoryRepository: Failed to update category - \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func deleteCategory(withId id: UUID) -> Result<Void, Error> {
        print("CategoryRepository: Attempting to delete category ID: \(id)")
        
        guard getCategory(withId: id) != nil else {
            print("CategoryRepository: Failed to find category with ID: \(id)")
            return .failure(NSError(domain: "CategoryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Category not found"]))
        }
        
        let operations = dataStore.getOperations(forCategory: id)
        if !operations.isEmpty {
            print("CategoryRepository: Cannot delete category ID: \(id) - it has \(operations.count) operations")
            return .failure(NSError(domain: "CategoryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot delete category with associated operations"]))
        }
        
        print("CategoryRepository: Deleting category ID: \(id)")
        dataStore.deleteCategory(withId: id)
        return .success(())
    }
    
    enum RepositoryError: Error, LocalizedError {
        case categoryNotFound
        case categoryHasOperations
        
        var errorDescription: String? {
            switch self {
            case .categoryNotFound:
                return "Категория не найдена"
            case .categoryHasOperations:
                return "Невозможно удалить категорию, так как с ней связаны операции"
            }
        }
    }
}
