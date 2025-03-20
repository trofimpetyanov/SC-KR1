





import SwiftUI

@main
struct BankHSEApp: App {
    
    private let container = DIContainer.shared
    
    init() {
        
        _ = container
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("ВШЭ-банк запущен!")
                }
        }
    }
}
