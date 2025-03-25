import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager
    
    var defaultDate: Date = Date()
    var transactionToEdit: Transaction?
    @State private var scannedTitle: String?
    @State private var scannedAmount: String?
    @State private var scannedDate: Date?
    
    init(defaultDate: Date = Date(), transactionToEdit: Transaction? = nil, scannedTitle: String? = nil, scannedAmount: String? = nil, scannedDate: Date? = nil) {
        self.defaultDate = defaultDate
        self.transactionToEdit = transactionToEdit
        _scannedTitle = State(initialValue: scannedTitle)
        _scannedAmount = State(initialValue: scannedAmount)
        _scannedDate = State(initialValue: scannedDate)
            _transactionDate = State(initialValue: scannedDate ?? defaultDate)
    }

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory = ""
    @State private var transactionDate: Date
    @State private var transactionType: TransactionType = .expense // choose expense or income
    @State private var isPresentingCategoryManager = false

    var body: some View {
        NavigationView {
            Form {
                // Segmented control to select transaction type
                Picker("Type", selection: $transactionType) {
                    Text("Expense").tag(TransactionType.expense)
                    Text("Income").tag(TransactionType.income)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: transactionType) { newValue in
                    if newValue == .expense {
                        selectedCategory = categoryManager.expenseCategories.first ?? ""
                    } else {
                        selectedCategory = categoryManager.incomeCategories.first ?? ""
                    }
                }
                
                Section(header: Text("Transaction Details")) {
                    
                    TextField("Title", text: $title)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
            
                }
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        if transactionType == .expense {
                            ForEach(categoryManager.expenseCategories, id: \.self) { category in
                                Text(category)
                            }
                        } else {
                            ForEach(categoryManager.incomeCategories, id: \.self) { category in
                                Text(category)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Button("Manage Categories") {
                        isPresentingCategoryManager = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle(transactionToEdit == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    guard let amountValue = Double(amount), !title.isEmpty else { return }
                    if let editingTransaction = transactionToEdit,
                       let index = transactionStore.transactions.firstIndex(where: { $0.id == editingTransaction.id }) {
                        // Update the existing transaction.
                        transactionStore.transactions[index].title = title
                        transactionStore.transactions[index].amount = amountValue
                        transactionStore.transactions[index].date = transactionDate
                        transactionStore.transactions[index].category = selectedCategory
                        transactionStore.transactions[index].type = transactionType
                    } else {
                        // Create a new transaction.
                        let newTransaction = Transaction(
                            title: title,
                            amount: amountValue,
                            date: transactionDate,
                            category: selectedCategory,
                            type: transactionType
                        )
                        transactionStore.transactions.append(newTransaction)
                    }
                    scannedTitle = nil
                    scannedAmount = nil
                    scannedDate = nil
                    dismiss()
                }
            )
            .sheet(isPresented: $isPresentingCategoryManager) {
                CategoryManagerView(transactionType: transactionType)
                    .environmentObject(categoryManager)
                
            }
            
            
            .onAppear {
                print("scannedTitle: \(scannedTitle ?? "nil")")
                print("scannedAmount: \(scannedAmount ?? "nil")")
                print("scannedDate: \(scannedDate?.description ?? "nil")")
                
                if let transaction = transactionToEdit {
                    title = transaction.title
                    amount = String(transaction.amount)
                    transactionDate = transaction.date
                    transactionType = transaction.type
                    selectedCategory = transaction.category
                } else {
                    // For new transactions, if scanned data is available, use them
                    if let scannedTitle = scannedTitle {
                        title = scannedTitle
                    }
                    if let scannedAmount = scannedAmount {
                        amount = scannedAmount
                    }
                    if let scannedDate = scannedDate {
                        transactionDate = scannedDate
                    } else {
                        transactionDate = defaultDate
                    }
                
                    
                    // Set default category based on transaction type.
                    if transactionType == .expense {
                        selectedCategory = categoryManager.expenseCategories.first ?? ""
                    } else {
                        selectedCategory = categoryManager.incomeCategories.first ?? ""
                    }
//                    transactionDate = defaultDate
                }
                
            }
        }
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    @State static var previewTransactions: [Transaction] = []
    
    static var previews: some View {
        AddTransactionView()
            .environmentObject(TransactionStore())
            .environmentObject(CategoryManager())
    }
}
