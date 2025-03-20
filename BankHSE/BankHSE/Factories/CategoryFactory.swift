import Foundation

class CategoryFactory {
    static func create(name: String, type: OperationType) throws -> Category {
        if name.isEmpty {
            throw NSError(domain: "CategoryValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Category name cannot be empty"])
        }
        
        if name.count > 30 {
            throw NSError(domain: "CategoryValidationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Category name cannot exceed 30 characters"])
        }
        
        let category = Category(id: UUID(), type: type, name: name)
        return category
    }
    
    static func update(category: Category, name: String) throws -> Category {
        if name.isEmpty {
            throw NSError(domain: "CategoryValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Category name cannot be empty"])
        }
        
        if name.count > 30 {
            throw NSError(domain: "CategoryValidationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Category name cannot exceed 30 characters"])
        }
        
        print("CategoryFactory: Creating new Category instance for ID: \(category.id) with name updated from '\(category.name)' to '\(name)'")
        
        let updatedCategory = Category(id: category.id, type: category.type, name: name)
        return updatedCategory
    }
}
