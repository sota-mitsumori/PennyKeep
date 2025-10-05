import SwiftUI



struct TransactionsView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var appSettings: AppSettings
    
    // Enum to manage which sheet is active. Conforms to Identifiable.
    enum ActiveSheet: Identifiable {
        case add
        case edit(Transaction)
        case scanner

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let trans): return "edit-\(trans.id.uuidString)"
            case .scanner: return "scanner"
            }
        }
    }

    @State private var activeSheet: ActiveSheet?
    @State private var selectedDate: Date = Date()
    @State private var scannedData: (title: String, amount: String, date: Date)? = nil
    @State private var isLoading: Bool = false
    @State private var isMenuExpanded: Bool = false

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
                                activeSheet = .edit(transaction)
                            })
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .safeAreaInset(edge: .bottom) {
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            .navigationTitle("Transactions")
            .sheet(item: $activeSheet) { item in
                switch item {
                case .add:
                    AddTransactionView(defaultDate: selectedDate, transactionToEdit: nil, scannedData: $scannedData)
                        .id(UUID())
                        .environmentObject(transactionStore)
                        .environmentObject(CategoryManager())
                case .edit(let transaction):
                    AddTransactionView(defaultDate: transaction.date, transactionToEdit: transaction, scannedData: $scannedData)
                        .id(UUID())
                        .environmentObject(transactionStore)
                        .environmentObject(CategoryManager())
                case .scanner:
                    ReceiptScannerView { scannedTitle, scannedAmount, scannedDate in
                        scannedData = (scannedTitle, scannedAmount, scannedDate)
                        activeSheet = nil // Dismiss scanner
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            activeSheet = .add // Present add transaction sheet
                            isLoading = false
                        }
                    }
                }
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
        .overlay(
            ZStack(alignment: .bottomTrailing) {
                if isMenuExpanded {
                    VStack(spacing: 16) {
                        Button(action: {
                            scannedData = nil
                            activeSheet = .add
                            isMenuExpanded = false
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 24))
                                .padding(20)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .frame(width: 64, height: 64)
                        }
                        Button(action: {
                            activeSheet = .scanner
                            isMenuExpanded = false
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .padding(20)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .frame(width: 64, height: 64)
                        }
                    }
                    .transition(.scale)
                    .offset(y: -80)
                }
                Button(action: {
                    withAnimation {
                        isMenuExpanded.toggle()
                    }
                }) {
                    Image(systemName: isMenuExpanded ? "xmark" : "plus")
                        .font(.system(size: 24))
                        .padding(20)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .frame(width: 64, height: 64)
                }
            }
            .padding(),
            alignment: .bottomTrailing
        )
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
            .environmentObject(TransactionStore())
            .environmentObject(AppSettings())
    }
}
