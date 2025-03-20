import Foundation

class CategoriesFacade {
    private let categoryRepository: CategoryRepository
    private var diContainer: DIContainer?
    
    init(categoryRepository: CategoryRepository, diContainer: DIContainer? = DIContainer.shared) {
        self.categoryRepository = categoryRepository
        self.diContainer = diContainer
    }
    
    
    func setDIContainer(_ container: DIContainer) {
        self.diContainer = container
    }
    
    
    
    func getAllCategories() -> [Category] {
        return categoryRepository.getAllCategories()
    }
    
    func getCategories(ofType type: OperationType) -> [Category] {
        return categoryRepository.getCategories(ofType: type)
    }
    
    func getCategory(withId id: UUID) -> Category? {
        return categoryRepository.getCategory(withId: id)
    }
    
    func createCategory(name: String, type: OperationType) -> Result<Category, Error> {
        let result = categoryRepository.createCategory(name: name, type: type)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func updateCategory(id: UUID, name: String) -> Result<Category, Error> {
        let result = categoryRepository.updateCategory(id: id, name: name)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func updateCategory(_ category: Category) -> Result<Category, Error> {
        let result = categoryRepository.updateCategory(id: category.id, name: category.name)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
    
    func deleteCategory(withId id: UUID) -> Result<Void, Error> {
        let result = categoryRepository.deleteCategory(withId: id)
        if case .success = result {
            diContainer?.notifyDataChanged()
        }
        return result
    }
}
