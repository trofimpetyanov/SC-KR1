import SwiftUI

struct SettingsView: View {
    @State private var showingExportImport = false
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: DataExportImportView()) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.on.square")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text("Импорт/Экспорт данных")
                                .font(.headline)
                            Text("YAML, JSON, CSV")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Данные")
            }
        }
        .navigationTitle("Настройки")
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
} 