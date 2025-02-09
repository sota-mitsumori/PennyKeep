import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @State private var isPresentingAddTransaction = false
    @State private var selectedDate: Date = Date() // Filter date from the calendar

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
                                    Text(String(format: "$%.2f", transaction.amount))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                // Color-code based on type: green for income, red for expense.
                                if transaction.type == .income {
                                    Text("Income")
                                        .foregroundColor(.green)
                                } else {
                                    Text("Expense")
                                        .foregroundColor(.red)
                                }
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

