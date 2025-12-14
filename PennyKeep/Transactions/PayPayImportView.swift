import SwiftUI
import UniformTypeIdentifiers

struct PayPayImportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var appSettings: AppSettings
    
    let csvURL: URL?
    
    @State private var showSuccessAlert = false
    @State private var savedCount = 0
    
    @State private var importedTransactions: [PayPayTransaction] = []
    @State private var selectedTransactions: Set<String> = []
    @State private var showDocumentPicker = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var transactionToEdit: PayPayTransaction?
    
    init(csvURL: URL? = nil) {
        self.csvURL = csvURL
    }
    
    var body: some View {
        NavigationView {
            Group {
                if importedTransactions.isEmpty {
                    // インポート前の画面
                    VStack(spacing: 24) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                        
                        Text("Import PayPay Transactions")
                            .font(.title2)
                            .bold()
                        
                        Text("Select a CSV file downloaded from the PayPay app")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showDocumentPicker = true
                        }) {
                            Label("Select CSV File", systemImage: "folder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accentColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                } else {
                    // インポート後のプレビュー画面
                    VStack(spacing: 0) {
                        // ヘッダー
                        HStack {
                            Text("\(importedTransactions.count) transactions found")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                selectedTransactions = Set(importedTransactions.map { $0.id })
                            }) {
                                Text("Select All")
                                    .font(.subheadline)
                            }
                            Button(action: {
                                selectedTransactions.removeAll()
                            }) {
                                Text("Deselect All")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        
                        // Transaction list
                        List {
                            ForEach(importedTransactions) { transaction in
                                PayPayTransactionRow(
                                    transaction: transaction,
                                    isSelected: selectedTransactions.contains(transaction.id),
                                    onToggle: {
                                        if selectedTransactions.contains(transaction.id) {
                                            selectedTransactions.remove(transaction.id)
                                        } else {
                                            selectedTransactions.insert(transaction.id)
                                        }
                                    },
                                    onEdit: {
                                        transactionToEdit = transaction
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("PayPay Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // If CSV URL is provided (from Share Extension), load it automatically
                if let url = csvURL {
                    loadCSVFromURL(url)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !importedTransactions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveSelectedTransactions()
                        }
                        .disabled(selectedTransactions.isEmpty || isProcessing)
                    }
                }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Saved", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Saved \(savedCount) transaction\(savedCount == 1 ? "" : "s")")
            }
            .sheet(item: $transactionToEdit) { transaction in
                PayPayTransactionEditViewWrapper(
                    transaction: transaction,
                    onSave: { updated in
                        if let index = importedTransactions.firstIndex(where: { $0.id == updated.id }) {
                            importedTransactions[index] = updated
                        }
                        transactionToEdit = nil
                    },
                    onCancel: {
                        transactionToEdit = nil
                    }
                )
                .environmentObject(categoryManager)
                .environmentObject(appSettings)
            }
        }
    }
    
    private func loadCSVFromURL(_ url: URL) {
        isProcessing = true
        errorMessage = nil
        
        // Read file
        do {
            let csvContent = try String(contentsOf: url, encoding: .utf8)
            let transactions = PayPayCSVParser.parse(csvContent)
            
            DispatchQueue.main.async {
                self.importedTransactions = transactions
                // Select all transactions by default
                self.selectedTransactions = Set(transactions.map { $0.id })
                self.isProcessing = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to read file: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        isProcessing = true
        errorMessage = nil
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "No file selected"
                isProcessing = false
                return
            }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                DispatchQueue.main.async {
                    self.errorMessage = "Permission denied to access file"
                    self.isProcessing = false
                }
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            loadCSVFromURL(url)
            
        case .failure(let error):
            DispatchQueue.main.async {
                self.errorMessage = "File selection error: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    private func saveSelectedTransactions() {
        isProcessing = true
        
        let transactionsToSave = importedTransactions.filter { selectedTransactions.contains($0.id) }
        savedCount = transactionsToSave.count
        
        // Refresh categories
        categoryManager.refreshCategories()
        
        for payPayTransaction in transactionsToSave {
            // Use edited values if available, otherwise use defaults
            let title = payPayTransaction.editedTitle ?? payPayTransaction.displayTitle
            let category = payPayTransaction.editedCategory ?? (payPayTransaction.isExpense ? (categoryManager.expenseCategories.first ?? "Other") : (categoryManager.incomeCategories.first ?? "Other"))
            let type = payPayTransaction.editedType ?? (payPayTransaction.isExpense ? TransactionType.expense : TransactionType.income)
            
            let transaction = Transaction(
                title: title,
                amount: abs(payPayTransaction.amount),
                originalAmount: abs(payPayTransaction.amount),
                date: payPayTransaction.dateTime,
                category: category,
                type: type,
                currency: appSettings.selectedCurrency,
                paymentMethod: .qrCode // PayPay is treated as QR code payment
            )
            
            transactionStore.addTransaction(transaction)
        }
        
        // Refresh transactions
        transactionStore.refreshTransactions()
        
        isProcessing = false
        showSuccessAlert = true
    }
}

struct PayPayTransactionRow: View {
    let transaction: PayPayTransaction
    let isSelected: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayTitle)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let editedCategory = transaction.editedCategory {
                        Text(editedCategory)
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text(transaction.transactionType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if transaction.editedTitle != nil || transaction.editedCategory != nil {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Text(transaction.dateTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(abs(transaction.amount), format: .currency(code: "JPY"))
                    .font(.headline)
                    .foregroundColor(transaction.isExpense ? .red : .green)
                
                Text(transaction.isExpense ? "Expense" : "Income")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}
