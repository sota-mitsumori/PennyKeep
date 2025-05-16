import SwiftUI

// Helper to decode dynamic currency JSON
private struct RawCurrencyResponse: Decodable {
    let date: String
    let rates: [String: Double]
    
    private struct DynamicKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        // Decode the "date" field
        date = try container.decode(String.self, forKey: DynamicKey(stringValue: "date")!)
        // Determine the dynamic base key (e.g. "eur", "usd")
        let allKeys = container.allKeys.filter { $0.stringValue != "date" }
        guard let baseKey = allKeys.first else {
            rates = [:]
            return
        }
        // Decode nested rates dictionary under the baseKey
        let nested = try container.nestedContainer(keyedBy: DynamicKey.self, forKey: baseKey)
        var dict = [String: Double]()
        for key in nested.allKeys {
            dict[key.stringValue] = try nested.decode(Double.self, forKey: key)
        }
        rates = dict
    }
}


struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var appSettings: AppSettings
    @State private var transactionCurrency: String = ""
    
    private func saveTransaction(with amountValue: Double) {
        if let editingTransaction = transactionToEdit,
           let index = transactionStore.transactions.firstIndex(where: { $0.id == editingTransaction.id }) {
            transactionStore.transactions[index].title = title
            transactionStore.transactions[index].amount = amountValue
            transactionStore.transactions[index].date = transactionDate
            transactionStore.transactions[index].category = selectedCategory
            transactionStore.transactions[index].type = transactionType
//            transactionStore.transactions[index].currency = transactionCurrency
        } else {
            let newTransaction = Transaction(
                title: title,
                amount: amountValue,
                date: transactionDate,
                category: selectedCategory,
                type: transactionType,
//                currency: transactionCurrency
            )
            transactionStore.transactions.append(newTransaction)
        }
        scannedData = nil
        dismiss()
    }
    
    var defaultDate: Date = Date()
    var transactionToEdit: Transaction?
    @Binding var scannedData: (title: String, amount: String, date: Date)?
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory = ""
    @State private var transactionDate: Date
    @State private var transactionType: TransactionType = .expense // choose expense or income
    @State private var isPresentingCategoryManager = false
    
    init(defaultDate: Date = Date(), transactionToEdit: Transaction? = nil, scannedData: Binding<(title: String, amount: String, date: Date)?> ) {
        self.defaultDate = defaultDate
        self.transactionToEdit = transactionToEdit
        self._scannedData = scannedData
        
        if let data = scannedData.wrappedValue {
            _transactionDate = State(initialValue: data.date)
        } else {
            _transactionDate = State(initialValue: defaultDate)
        }
    }


    var body: some View {
        NavigationView {
            Form {
                // Segmented control to select transaction type
                Picker("Type", selection: $transactionType) {
                    Text("Expense").tag(TransactionType.expense)
                    Text("Income").tag(TransactionType.income)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: transactionType) {
                    if transactionType == .expense {
                        selectedCategory = categoryManager.expenseCategories.first ?? ""
                    } else {
                        selectedCategory = categoryManager.incomeCategories.first ?? ""
                    }
                }
                
                Section(header: Text("Transaction Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Currency", selection: $transactionCurrency) {
                        ForEach(currencyItems) { item in
                            Text("\(item.code) – \(item.name)")
                                .tag(item.code)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
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
                    let base = transactionCurrency.lowercased()
                    let target = appSettings.selectedCurrency.lowercased()
                    if base == target {
                        // No conversion needed
                        saveTransaction(with: amountValue)
                    } else {
                        // Format the user-selected transaction date for historical rates
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let dateString = dateFormatter.string(from: transactionDate)
                        let urlString = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@\(dateString)/v1/currencies/\(base).json"
                        guard let url = URL(string: urlString) else { return }
                        URLSession.shared.dataTask(with: url) { data, _, error in
                            guard let data = data, error == nil else { return }
                            do {
                                let response = try JSONDecoder().decode(RawCurrencyResponse.self, from: data)
                                let rate = response.rates[target] ?? 1.0
                                let convertedAmount = amountValue * rate
                                DispatchQueue.main.async {
                                    saveTransaction(with: convertedAmount)
                                }
                            } catch {
                                print("Currency conversion error:", error)
                                DispatchQueue.main.async {
                                    // Fallback to the original amount
                                    saveTransaction(with: amountValue)
                                }
                            }
                        }.resume()
                    }
                }
            )
            .sheet(isPresented: $isPresentingCategoryManager) {
                CategoryManagerView(transactionType: transactionType)
                    .environmentObject(categoryManager)
                
            }
            
            
            .onAppear {
                if let transaction = transactionToEdit {
                    title = transaction.title
                    amount = String(transaction.amount)
                    transactionDate = transaction.date
                    transactionType = transaction.type
                    selectedCategory = transaction.category
//                    transactionCurrency = transaction.currency
                } else {
                    if let data = scannedData {
                        title = data.title
                        amount = data.amount
                        transactionDate = data.date
                    } else {
                        transactionDate = defaultDate
                    }
                
                    
                    // Set default category based on transaction type.
                    if transactionType == .expense {
                        selectedCategory = categoryManager.expenseCategories.first ?? ""
                    } else {
                        selectedCategory = categoryManager.incomeCategories.first ?? ""
                    }
                    transactionCurrency = appSettings.selectedCurrency
//                    transactionDate = defaultDate
                }
                
            }
        }
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    @State static var previewScannedData: (title: String, amount: String, date: Date)? = nil
    
    static var previews: some View {
        AddTransactionView(scannedData: $previewScannedData)
            .environmentObject(TransactionStore())
            .environmentObject(CategoryManager())
            .environmentObject(AppSettings())
    }
}
