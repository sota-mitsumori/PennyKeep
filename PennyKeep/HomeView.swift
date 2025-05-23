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
        let calendar = Calendar.current
        return transactionStore.transactions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .sorted { $0.date > $1.date }
    }

    // Group recent transactions by category
    private var recentTransactionsByCategory: [(category: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: recentTransactions) { $0.category }
        return grouped.map { (category: $0.key, transactions: $0.value) }
            .sorted { $0.category < $1.category }
    }

    // Computed array of totals for the last 12 months
    private var monthlyTotals: [(month: Date, income: Double, expense: Double)] {
        let calendar = Calendar.current
        return (0..<12).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let transactions = transactionStore.transactions.filter {
                calendar.isDate($0.date, equalTo: date, toGranularity: .month)
            }
            let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return (month: date, income: income, expense: expense)
        }.reversed()
    }

    // Formatter to display month and year
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Monthly Totals section.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(monthlyTotals, id: \.month) { total in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(Self.monthFormatter.string(from: total.month))
                                        .font(.headline)
                                    if appSettings.selectedCurrency == "¥" {
                                        Text("¥\(String(format: "%.0f", total.income))")
                                            .foregroundColor(.green)
                                        Text("¥\(String(format: "%.0f", total.expense))")
                                            .foregroundColor(.red)
                                    } else {
                                        Text("\(appSettings.selectedCurrency)\(String(format: "%.2f", total.income))")
                                            .foregroundColor(.green)
                                        Text("\(appSettings.selectedCurrency)\(String(format: "%.2f", total.expense))")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent Transactions by Category
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Transactions")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(recentTransactionsByCategory, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.category)
                                    .font(.headline)
                                    .padding()
                                
                                ForEach(group.transactions) { transaction in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(transaction.date, style: .date)
                                                .font(.caption)
                                            Text(transaction.title)
                                                .font(.subheadline)
                                                .bold()
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
                                    .padding(.vertical, 4)
                                    .padding(.horizontal)
                                    Divider()
                                }
                            }
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Home")
        }
    }
}
