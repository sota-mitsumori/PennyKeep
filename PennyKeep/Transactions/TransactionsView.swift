import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var isPresentingAddTransaction = false
    @State private var selectedDate: Date = Date()

    // Filter transactions based on the selected date.
    var filteredTransactions: [Transaction] {
        transactionStore.transactions.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Calendar at the top for date selection.
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding([.horizontal, .top])
                
                if filteredTransactions.isEmpty {
                    Spacer()
                    Text("No transactions for this day")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredTransactions) { transaction in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(transaction.title)
                                        .font(.headline)
                                    Text(transaction.category)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                // Display amount with a + for income and - for expense.
                                Text("\(transaction.type == .income ? "+" : "-")\(appSettings.selectedCurrency)\(String(format: "%.2f", transaction.amount))")
                                    .font(.headline)
                                    .foregroundColor(transaction.type == .income ? .green : .red)
                                
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTransaction) {
                AddTransactionView()
                    .environmentObject(transactionStore)
                    .environmentObject(CategoryManager())
            }
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
            .environmentObject(TransactionStore())
    }
}

