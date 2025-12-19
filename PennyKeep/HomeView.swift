import SwiftUI
import Charts

struct PaymentMethodData: Identifiable {
    var id: String { paymentMethod.rawValue }
    let paymentMethod: PaymentMethod
    let amount: Double
    let percentage: Double
}

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
    
    // 支払い方法別の支出データ
    var paymentMethodData: [PaymentMethodData] {
        let expenseTransactions = currentMonthTransactions.filter { $0.type == .expense }
        let totalExpense = expenseTotal
        
        guard totalExpense > 0 else { return [] }
        
        var data: [PaymentMethodData] = []
        let grouped = Dictionary(grouping: expenseTransactions) { $0.paymentMethod }
        
        for (method, transactions) in grouped {
            let amount = transactions.reduce(0) { $0 + $1.amount }
            let percentage = (amount / totalExpense) * 100
            data.append(PaymentMethodData(
                paymentMethod: method,
                amount: amount,
                percentage: percentage
            ))
        }
        
        return data.sorted { $0.amount > $1.amount }
    }
    
    var recentTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactionStore.transactions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .sorted { $0.date > $1.date }
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
                                    Text(total.income, format: .currency(code: appSettings.selectedCurrency))
                                        .foregroundColor(.green)
                                    Text(total.expense, format: .currency(code: appSettings.selectedCurrency))
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Payment Method Breakdown section
                    if !paymentMethodData.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Methods")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            // Chart
                            Chart(paymentMethodData) { item in
                                SectorMark(
                                    angle: .value("Amount", item.amount),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 2
                                )
                                .cornerRadius(5)
                                .foregroundStyle(by: .value("Method", item.paymentMethod.displayName))
                            }
                            .frame(height: 200)
                            .chartLegend(alignment: .center, spacing: 12)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // List of payment methods
                            VStack(spacing: 8) {
                                ForEach(paymentMethodData) { item in
                                    HStack {
                                        Image(systemName: item.paymentMethod.iconName)
                                            .font(.system(size: 20))
                                            .foregroundColor(.accentColor)
                                            .frame(width: 30)
                                        
                                        Text(item.paymentMethod.displayName)
                                            .font(.body)
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(item.amount, format: .currency(code: appSettings.selectedCurrency))
                                                .font(.headline)
                                            Text("\(item.percentage, specifier: "%.1f")%")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Recent Transactions List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Transactions")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        if recentTransactions.isEmpty {
                            Text("No recent transactions")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        } else {
                            ForEach(recentTransactions) { transaction in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(transaction.title)
                                            .font(.headline)
                                        Text(transaction.category)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(transaction.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    let formattedAmount = transaction.amount.formatted(.currency(code: appSettings.selectedCurrency))
                                    Text("\(transaction.type == .income ? "+" : "-")\(formattedAmount)")
                                        .font(.headline)
                                        .foregroundColor(transaction.type == .income ? .green : .red)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Home")
        }
    }
}
