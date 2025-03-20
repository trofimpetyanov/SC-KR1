import SwiftUI
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()
    
    
    @Published var refreshCounter: Int = 0
    
    private init() {}
    
    
    func forceRefresh() {
        print("AppState: FORCING UI REFRESH!")
        DispatchQueue.main.async {
            self.refreshCounter += 1
        }
    }
}

struct ForceRefreshable: ViewModifier {
    @ObservedObject private var appState = AppState.shared
    
    
    private var forceRefreshValue: Int {
        return appState.refreshCounter
    }
    
    func body(content: Content) -> some View {
        content
            .id("refresh_\(forceRefreshValue)")
    }
}

extension View {
    func forceRefreshable() -> some View {
        self.modifier(ForceRefreshable())
    }
} 
