import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let onEdit: () -> Void
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
         HStack {
              VStack(alignment: .leading) {
                  Text(transaction.title)
                      .font(.headline)
                  Text(transaction.category)
                      .font(.subheadline)
                      .foregroundColor(.secondary)
              }
              Spacer()
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
              // Delete action
              Button(role: .destructive) {
                  if let index = transactionStore.transactions.firstIndex(where: { $0.id == transaction.id }) {
                      transactionStore.transactions.remove(at: index)
                  }
              } label: {
                  Label("Delete", systemImage: "trash")
              }
              
              // Edit action
              Button {
                  onEdit()
              } label: {
                  Label("Edit", systemImage: "pencil")
              }
              .tint(.blue)
         }
    }
}

struct TransactionsView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var transactionToEdit: Transaction? = nil
    @State private var isEditing: Bool = false
    @State private var isPresentingAddTransaction: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var isPresentingReceiptScanner: Bool = false
    @State private var scannedData: (title: String, amount: String, date: Date)? = nil
    @State private var isLoading: Bool = false

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
                            TransactionRow(transaction: transaction, onEdit: {
                                transactionToEdit = transaction
                                isPresentingAddTransaction = true
                            })
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
                        scannedData = nil
                        isPresentingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        transactionToEdit = nil
                        isPresentingReceiptScanner = true
                    }) {
                        Image(systemName: "camera.fill")
                    }
                    .tint(.blue)
                }
            }
            .sheet(isPresented: $isPresentingReceiptScanner) {
                ReceiptScannerView { scannedTitle, scannedAmount, scannedDate in
                    scannedData = (scannedTitle, scannedAmount, scannedDate)
                    isPresentingReceiptScanner = false
                    isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isPresentingAddTransaction = true
                        isLoading = false
                    }
                }
            }
            
            .sheet(isPresented: $isPresentingAddTransaction) {
                AddTransactionView(defaultDate: selectedDate, transactionToEdit: transactionToEdit, scannedData: $scannedData)
                    .id(UUID())
                    .environmentObject(transactionStore)
                    .environmentObject(CategoryManager())
            }
            
        }
        .overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading...")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        )
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
            .environmentObject(TransactionStore())
    }
}
