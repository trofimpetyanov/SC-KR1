import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var selectedPeriod: DatePeriod = .month
    @State private var startDate: Date = Date().startOfMonth()
    @State private var endDate: Date = Date()
    @State private var categories: [Category] = []
    @State private var topIncomeCategories: [(UUID, Double)] = []
    @State private var topExpenseCategories: [(UUID, Double)] = []
    @State private var incomeExpenseDifference: Double = 0
    
    private let facade: BankHSE.AnalyticsFacade
    private let categoriesFacade: CategoriesFacade
    
    init(facade: BankHSE.AnalyticsFacade, categoriesFacade: CategoriesFacade) {
        self.facade = facade
        self.categoriesFacade = categoriesFacade
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Период анализа")) {
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(DatePeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .onChange(of: selectedPeriod) {
                        updateDates()
                        updateAnalytics()
                    }
                    
                    if selectedPeriod != .custom {
                        HStack {
                            Text("Период")
                            Spacer()
                            Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        DatePicker("Начало периода", selection: $startDate, displayedComponents: [.date])
                            .onChange(of: startDate) { 
                                if startDate > endDate {
                                    endDate = startDate
                                }
                                updateAnalytics() 
                            }
                        
                        DatePicker("Конец периода", selection: $endDate, in: startDate..., displayedComponents: [.date])
                            .onChange(of: endDate) { 
                                updateAnalytics() 
                            }
                    }
                }
                
                Section(header: Text("Итог за период")) {
                    HStack {
                        Text("Разница доходов и расходов")
                            .font(.subheadline)
                        Spacer()
                        Text(incomeExpenseDifference.formattedAsCurrency())
                            .font(.headline)
                            .foregroundColor(incomeExpenseDifference >= 0 ? .green : .red)
                    }
                }
                
                if !topIncomeCategories.isEmpty {
                    Section(header: Text("Топ категорий доходов")) {
                        ForEach(topIncomeCategories, id: \.0) { categoryTuple in
                            HStack {
                                Text(getCategoryName(for: categoryTuple.0))
                                    .font(.subheadline)
                                Spacer()
                                Text(categoryTuple.1.formattedAsCurrency())
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                if !topExpenseCategories.isEmpty {
                    Section(header: Text("Топ категорий расходов")) {
                        ForEach(topExpenseCategories, id: \.0) { categoryTuple in
                            HStack {
                                Text(getCategoryName(for: categoryTuple.0))
                                    .font(.subheadline)
                                Spacer()
                                Text(categoryTuple.1.formattedAsCurrency())
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Аналитика")
            .onAppear {
                updateDates()
                loadData()
                updateAnalytics()
                
                
                setupNotificationObserver()
            }
            .onDisappear {
                
                removeNotificationObserver()
            }
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .dataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            loadData()
            updateAnalytics()
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: .dataDidChange, object: nil)
    }
    
    private func loadData() {
        categories = categoriesFacade.getAllCategories()
    }
    
    private func updateDates() {
        let today = Date()
        
        switch selectedPeriod {
        case .week:
            
            startDate = today.startOfWeek()
            endDate = today
        case .month:
            
            startDate = today.startOfMonth()
            endDate = today
        case .quarter:
            
            startDate = today.startOfQuarter()
            endDate = today
        case .year:
            
            startDate = today.startOfYear()
            endDate = today
        case .custom:
            
            break
        }
    }
    
    private func updateAnalytics() {
        incomeExpenseDifference = facade.getIncomeExpenseDifference(inPeriod: startDate, endDate: endDate)
        topIncomeCategories = facade.getTopCategories(ofType: .income, inPeriod: startDate, endDate: endDate)
        topExpenseCategories = facade.getTopCategories(ofType: .expense, inPeriod: startDate, endDate: endDate)
    }
    
    private func getCategoryName(for id: UUID) -> String {
        return categories.first { $0.id == id }?.name ?? "Неизвестная категория"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

enum DatePeriod: CaseIterable {
    case week
    case month
    case quarter
    case year
    case custom
    
    var displayName: String {
        switch self {
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .quarter: return "Квартал"
        case .year: return "Год"
        case .custom: return "Свой"
        }
    }
}

extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: self)
        return calendar.date(from: components)!
    }
    
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    func startOfQuarter() -> Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let quarter = (month - 1) / 3
        let components = DateComponents(year: calendar.component(.year, from: self), month: quarter * 3 + 1, day: 1)
        return calendar.date(from: components)!
    }
    
    func startOfYear() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)!
    }
}

#Preview {
    let dataStore = DataStoreProxy(dataStore: LocalDataStore())
    
    let categoryRepository = CategoryRepository(dataStore: dataStore)
    let operationFactory = OperationFactory(dataStore: dataStore)
    let operationRepository = OperationRepository(dataStore: dataStore, operationFactory: operationFactory)
    
    let categoriesFacade = CategoriesFacade(categoryRepository: categoryRepository)
    let analyticsFacade = BankHSE.AnalyticsFacade(operationRepository: operationRepository)
    
    AnalyticsView(facade: analyticsFacade, categoriesFacade: categoriesFacade)
}
