import SwiftUI

struct HomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var appSettings: AppSettings
    
    
    var currentMonthTransactions: [Transaction] {
        transactionStore.transactions.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
    }
    
    var incomeTotal: Double {
        currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var expenseTotal: Double {
       currentMonthTransactions
           .filter { $0.type == .expense }
           .reduce(0) { $0 + $1.amount }
    }
    
    
    var recentTransactions: [Transaction] {
        let sorted = transactionStore.transactions.sorted { $0.date > $1.date }
        return Array(sorted.prefix(5))
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Totals section.
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Month")
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Income")
                                    .font(.headline)
                                Text("\(appSettings.selectedCurrency)\(String(format: "%.2f", incomeTotal))")
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Expense")
                                    .font(.headline)
                                Text("\(appSettings.selectedCurrency)\(String(format: "%.2f", expenseTotal))")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Recent Transactions section.
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Transactions")
                            .font(.title2)
                            .bold()
                        
                        ForEach(recentTransactions) { transaction in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(transaction.date, style: .date)
                                        .font(.caption)
                                    Text(transaction.title)
                                        .font(.headline)
                                    Text(transaction.category)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(transaction.type == .income ? "+" : "-")\(appSettings.selectedCurrency)\(String(format: "%.2f", transaction.amount))")
                                    .font(.headline)
                                    .foregroundColor(transaction.type == .income ? .green : .red)
                            }
                            .padding(.vertical, 4)
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .navigationTitle("Home")
        }
    }
}

