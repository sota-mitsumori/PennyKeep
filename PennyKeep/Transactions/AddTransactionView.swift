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

    // Enum to manage sheet presentation
    private enum ActiveSheet: Identifiable {
        case manageCategories
        var id: Int { hashValue }
    }

    private func saveTransaction(originalAmount: Double, convertedAmount: Double) {
        if let editingTransaction = transactionToEdit,
           let index = transactionStore.transactions.firstIndex(where: { $0.id == editingTransaction.id }) {
            transactionStore.transactions[index].title = title
            transactionStore.transactions[index].amount = convertedAmount
            transactionStore.transactions[index].originalAmount = originalAmount
            transactionStore.transactions[index].date = transactionDate
            transactionStore.transactions[index].category = selectedCategory
            transactionStore.transactions[index].type = transactionType
            transactionStore.transactions[index].currency = transactionCurrency
        } else {
            let newTransaction = Transaction(
                title: title,
                amount: convertedAmount,
                originalAmount: originalAmount,
                date: transactionDate,
                category: selectedCategory,
                type: transactionType,
                currency: transactionCurrency
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
    @State private var originalAmountString: String = ""
    @State private var convertedAmount: Double = 0.0
    @State private var selectedCategory = ""
    @State private var transactionDate: Date
    @State private var transactionType: TransactionType = .expense
    @State private var activeSheet: ActiveSheet?

    init(defaultDate: Date = Date(), transactionToEdit: Transaction? = nil, scannedData: Binding<(title: String, amount: String, date: Date)?>) {
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
                    
                    TextField("Original Amount", text: $originalAmountString)
                        .keyboardType(.decimalPad)
                        .onChange(of: originalAmountString) {
                            let newValue = Double(originalAmountString) ?? 0.0
                            let base = transactionCurrency.lowercased()
                            let target = appSettings.selectedCurrency.lowercased()
                            if base == target {
                                convertedAmount = newValue
                            } else {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd"
                                let dateString = dateFormatter.string(from: transactionDate)
                                let endpoint = transactionDate > Date() ? "latest" : dateString
                                let urlString = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@\(endpoint)/v1/currencies/\(base).json"
                                guard let url = URL(string: urlString) else {
                                    convertedAmount = newValue
                                    return
                                }
                                URLSession.shared.dataTask(with: url) { data, _, error in
                                    guard let data = data, error == nil else {
                                        DispatchQueue.main.async { convertedAmount = newValue }
                                        return
                                    }
                                    do {
                                        let response = try JSONDecoder().decode(RawCurrencyResponse.self, from: data)
                                        let rate = response.rates[target] ?? 1.0
                                        let converted = newValue * rate
                                        DispatchQueue.main.async { convertedAmount = converted }
                                    } catch {
                                        DispatchQueue.main.async { convertedAmount = newValue }
                                    }
                                }.resume()
                            }
                        }
                    
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
                        activeSheet = .manageCategories
                    }
                    .foregroundColor(.blue)
                }

                if transactionCurrency.lowercased() != appSettings.selectedCurrency.lowercased() {
                    Section(header: Text("Converted Amount")) {
                        Text("\(convertedAmount, specifier: "%.2f") \(appSettings.selectedCurrency)")
                    }
                }
            }
            .navigationTitle(transactionToEdit == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    guard let amountValue = Double(originalAmountString), !title.isEmpty else { return }
                    let base = transactionCurrency.lowercased()
                    let target = appSettings.selectedCurrency.lowercased()
                    if base == target {
                        convertedAmount = amountValue
                        saveTransaction(originalAmount: amountValue, convertedAmount: amountValue)
                    } else {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let dateString = dateFormatter.string(from: transactionDate)
                        let endpoint = transactionDate > Date() ? "latest" : dateString
                        let urlString = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@\(endpoint)/v1/currencies/\(base).json"
                        guard let url = URL(string: urlString) else { return }
                        URLSession.shared.dataTask(with: url) { data, _, error in
                            guard let data = data, error == nil else { return }
                            do {
                                let response = try JSONDecoder().decode(RawCurrencyResponse.self, from: data)
                                let rate = response.rates[target] ?? 1.0
                                let converted = amountValue * rate
                                DispatchQueue.main.async {
                                    convertedAmount = converted
                                    saveTransaction(originalAmount: amountValue, convertedAmount: converted)
                                }
                            } catch {
                                print("Currency conversion error:", error)
                                DispatchQueue.main.async {
                                    convertedAmount = amountValue
                                    saveTransaction(originalAmount: amountValue, convertedAmount: amountValue)
                                }
                            }
                        }.resume()
                    }
                }
            )
            .sheet(item: $activeSheet) { item in
                switch item {
                case .manageCategories:
                    CategoryManagerView(transactionType: transactionType)
                        .environmentObject(categoryManager)
                }
            }
            .onAppear {
                if let transaction = transactionToEdit {
                    title = transaction.title
                    originalAmountString = String(format: "%.2f", transaction.originalAmount)
                    convertedAmount = transaction.amount
                    transactionDate = transaction.date
                    transactionType = transaction.type
                    selectedCategory = transaction.category
                    transactionCurrency = transaction.currency
                } else {
                    if let data = scannedData {
                        title = data.title
                        originalAmountString = data.amount
                        transactionDate = data.date
                    } else {
                        transactionDate = defaultDate
                    }
                    
                    if transactionType == .expense {
                        selectedCategory = categoryManager.expenseCategories.first ?? ""
                    } else {
                        selectedCategory = categoryManager.incomeCategories.first ?? ""
                    }
                    transactionCurrency = appSettings.selectedCurrency
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
