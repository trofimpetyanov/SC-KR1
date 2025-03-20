import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    private let container = DIContainer.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AccountsView(facade: container.getAccountsFacade())
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Счета")
                }
                .tag(0)
            
            OperationsView(
                facade: container.getOperationsFacade(),
                accountsFacade: container.getAccountsFacade(),
                categoriesFacade: container.getCategoriesFacade()
            )
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Операции")
                }
                .tag(1)
            
            CategoriesView(facade: container.getCategoriesFacade())
                .tabItem {
                    Image(systemName: "tag")
                    Text("Категории")
                }
                .tag(2)
            
            AnalyticsView(
                facade: container.getAnalyticsFacade(),
                categoriesFacade: container.getCategoriesFacade()
            )
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("Аналитика")
                }
                .tag(3)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Настройки")
            }
            .tag(4)
        }
        .forceRefreshable()
    }
}

#Preview {
    ContentView()
}
