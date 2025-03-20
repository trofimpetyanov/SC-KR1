import SwiftUI

struct OperationRow: View {
    let operation: Operation
    let accountName: String
    let categoryName: String
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(categoryName)
                    .font(.headline)
                
                Spacer()
                
                Text(operation.amount.formattedAsCurrency())
                    .font(.headline)
                    .foregroundColor(operation.type == .income ? .green : .red)
            }
            
            Text("Счет: \(accountName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(dateFormatter.string(from: operation.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let description = operation.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
} 