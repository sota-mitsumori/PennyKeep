import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var transactionToEdit: Transaction? = nil
    @State private var isEditing: Bool = false
    @State private var isPresentingAddTransaction: Bool = false
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
                                if appSettings.selectedCurrency == "¥" {
                                    Text("\(transaction.type == .income ? "+" : "-")¥\(String(format: "%.0f", transaction.amount))")
                                        .font(.headline)
                                        .foregroundColor(transaction.type == .income ? .green : .red)
                                } else {
                                    Text("\(transaction.type == .income ? "+" : "-")\(appSettings.selectedCurrency)\(String(format: "%.2f", transaction.amount))")
                                        .font(.headline)
                                        .foregroundColor(transaction.type == .income ? .green : .red)
                                }
                                
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                //Delete action
                                Button(role: .destructive) {
                                    if let index = transactionStore.transactions.firstIndex(where: {$0.id == transaction.id}) {
                                        transactionStore.transactions.remove(at: index)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                //Edit action
                                Button {
                                    transactionToEdit = transaction
                                    isPresentingAddTransaction = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
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
                        transactionToEdit = nil
                        isPresentingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTransaction) {
                AddTransactionView(defaultDate: selectedDate, transactionToEdit: transactionToEdit)
                    .id(transactionToEdit? .id)
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
