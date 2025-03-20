import Foundation

class AnalyticsFacade {
    private let operationRepository: OperationRepository
    
    init(operationRepository: OperationRepository) {
        self.operationRepository = operationRepository
    }
    
    
    
    func getIncomeExpenseDifference(inPeriod startDate: Date, endDate: Date) -> Double {
        return operationRepository.getIncomeExpenseDifference(inPeriod: startDate, endDate: endDate)
    }
    
    func getOperationsGroupedByCategory(inPeriod startDate: Date, endDate: Date) -> [UUID: Double] {
        return operationRepository.getOperationsGroupedByCategory(inPeriod: startDate, endDate: endDate)
    }
    
    func getBalanceDynamics(startDate: Date, endDate: Date, interval: Calendar.Component) -> [(Date, Double)] {
        let calendar = Calendar.current
        
        var currentDate = startDate
        var result: [(Date, Double)] = []
        var accumulatedBalance: Double = 0
        
        while currentDate <= endDate {
            var nextDate: Date
            
            switch interval {
            case .day:
                nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            case .weekOfMonth, .weekOfYear:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
            case .month:
                nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
            case .quarter:
                nextDate = calendar.date(byAdding: .quarter, value: 1, to: currentDate)!
            case .year:
                nextDate = calendar.date(byAdding: .year, value: 1, to: currentDate)!
            default:
                nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
            }
            
            
            let periodEnd = min(nextDate, endDate)
            let operations = operationRepository.getOperations(inPeriod: currentDate, endDate: periodEnd)
            
            
            var periodBalance: Double = 0
            for operation in operations {
                switch operation.type {
                case .income:
                    periodBalance += operation.amount
                case .expense:
                    periodBalance -= operation.amount
                }
            }
            
            
            accumulatedBalance += periodBalance
            result.append((currentDate, accumulatedBalance))
            
            currentDate = nextDate
        }
        
        return result
    }
    
    func getTopCategories(ofType type: OperationType, inPeriod startDate: Date, endDate: Date, limit: Int = 5) -> [(UUID, Double)] {
        
        let operations = operationRepository.getOperations(inPeriod: startDate, endDate: endDate)
            .filter { $0.type == type }
        
        var categoryTotals: [UUID: Double] = [:]
        
        for operation in operations {
            let categoryId = operation.categoryId
            if let existingTotal = categoryTotals[categoryId] {
                categoryTotals[categoryId] = existingTotal + operation.amount
            } else {
                categoryTotals[categoryId] = operation.amount
            }
        }
        
        let sortedResults = categoryTotals.sorted { $0.value > $1.value }
        
        return Array(sortedResults.prefix(limit))
    }
}
