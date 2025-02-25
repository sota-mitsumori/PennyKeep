import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory = "Transportation" // default category
    @State private var transactionDate: Date = Date() // selected date
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
            .navigationTitle("Add Transaction")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    if let amountValue = Double(amount), !title.isEmpty {
                        let newTransaction = Transaction(
                            title: title,
                            amount: amountValue,
                            date: transactionDate,
                            category: selectedCategory,
                            type: transactionType
                        )
                        transactionStore.transactions.append(newTransaction)
                    }
                    dismiss()
                }
            )
            .sheet(isPresented: $isPresentingCategoryManager) {
                CategoryManagerView(transactionType: transactionType)
                    .environmentObject(categoryManager)
            }
            .onAppear {
                // Initialize the selected category based on the default transaction type.
                if transactionType == .expense {
                    selectedCategory = categoryManager.expenseCategories.first ?? ""
                } else {
                    selectedCategory = categoryManager.incomeCategories.first ?? ""
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

