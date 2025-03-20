import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DataExportImportView: View {
    @State private var exportSuccess = false
    @State private var exportedFilePath = ""
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDocumentPicker = false
    @State private var showingExportPicker = false
    @State private var selectedFile: URL?
    @State private var showingImportConfirm = false
    @State private var selectedFormat: DataFormat = .yaml
    @State private var shouldStayOnScreen = false
    @Environment(\.dismiss) private var dismiss
    
    private let dataService = DataExportImportService.shared
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Формат")) {
                    Picker("Выберите формат", selection: $selectedFormat) {
                        ForEach(DataFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Экспорт")) {
                    Button("Экспортировать данные") {
                        showingExportPicker = true
                    }
                }
                
                Section(header: Text("Импорт")) {
                    Button("Выбрать файл для импорта") {
                        showingDocumentPicker = true
                    }
                }
            }
            .disabled(shouldStayOnScreen)
            .blur(radius: shouldStayOnScreen ? 5 : 0)
            
            if shouldStayOnScreen {
                VStack {
                    Text("Импорт успешно завершен")
                        .font(.headline)
                        .padding()
                    
                    Button("Вернуться к настройкам") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .frame(minWidth: 300, minHeight: 200)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                .shadow(radius: 10)
                .transition(.scale)
            }
        }
        .navigationTitle("Импорт/Экспорт")
        .alert("Экспорт завершен", isPresented: $showingExportSuccess) {
            Button("OK") {}
        } message: {
            Text("Данные успешно экспортированы в файл:\n\(exportedFilePath)")
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Подтверждение импорта", isPresented: $showingImportConfirm) {
            Button("Отмена", role: .cancel) {}
            Button("Импортировать", role: .destructive) {
                importData()
            }
        } message: {
            Text("Внимание! Импорт перезапишет все существующие данные. Вы уверены?")
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(selectedFormat: selectedFormat, forExport: false) { result in
                switch result {
                case .success(let url):
                    selectedFile = url
                    showingImportConfirm = true
                case .failure(let error):
                    if case ExportImportError.documentPickerCancelled = error {
                        
                    } else {
                        errorMessage = "Ошибка выбора файла: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportPicker) {
            DocumentPickerView(selectedFormat: selectedFormat, forExport: true) { result in
                switch result {
                case .success(let url):
                    exportData(to: url)
                case .failure(let error):
                    if case ExportImportError.documentPickerCancelled = error {
                        
                    } else {
                        errorMessage = "Ошибка выбора директории: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
        }
        .interactiveDismissDisabled(shouldStayOnScreen)
    }
    
    private func exportData(to directory: URL? = nil) {
        let result = dataService.exportData(format: selectedFormat, to: directory)
        
        switch result {
        case .success(let url):
            exportedFilePath = url.lastPathComponent
            showingExportSuccess = true
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func importData() {
        guard let fileURL = selectedFile else {
            errorMessage = "Файл не выбран"
            showingError = true
            return
        }
        
        let result = dataService.importData(from: fileURL)
        
        switch result {
        case .success:
            
            withAnimation {
                shouldStayOnScreen = true
            }
        case .failure(let error):
            errorMessage = "Ошибка импорта: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    var selectedFormat: DataFormat
    var forExport: Bool
    var completion: (Result<URL, Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        if forExport {
            
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
            picker.allowsMultipleSelection = false
            picker.delegate = context.coordinator
            return picker
        } else {
            
            let supportedTypes: [UTType] = [selectedFormat.utType]
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
            picker.allowsMultipleSelection = false
            picker.delegate = context.coordinator
            return picker
        }
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.completion(.failure(ExportImportError.documentPickerCancelled))
                return
            }
            
            parent.completion(.success(url))
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.completion(.failure(ExportImportError.documentPickerCancelled))
        }
    }
}

typealias YAMLExportImportView = DataExportImportView 
