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
    @State private var selectedMonthIndex: Int = 0
    
    
    var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let selectedMonth = monthlyTotals.indices.contains(selectedMonthIndex)
        ? monthlyTotals[selectedMonthIndex].month
        : Date()
        
        return transactionStore.transactions.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
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
        let selectedMonth = monthlyTotals.indices.contains(selectedMonthIndex)
        ? monthlyTotals[selectedMonthIndex].month
        : Date()
        return transactionStore.transactions
            .filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
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
            ZStack {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.15),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Monthly overview with paging and centered current month.
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Monthly Overview")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            if !monthlyTotals.isEmpty {
                                TabView(selection: $selectedMonthIndex) {
                                    ForEach(Array(monthlyTotals.indices), id: \.self) { index in
                                        let total = monthlyTotals[index]
                                        let net = total.income - total.expense
                                        
                                        VStack {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(Self.monthFormatter.string(from: total.month))
                                                            .font(.headline)
                                                            .foregroundColor(.secondary)
                                                        Text("Net Balance")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Text(net, format: .currency(code: appSettings.selectedCurrency))
                                                            .font(.title2.bold())
                                                            .foregroundColor(net >= 0 ? .green : .red)
                                                    }
                                                    Spacer()
                                                }
                                                
                                                HStack(spacing: 16) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("Income")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Text(total.income, format: .currency(code: appSettings.selectedCurrency))
                                                            .font(.headline)
                                                            .foregroundColor(.green)
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("Expense")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Text(total.expense, format: .currency(code: appSettings.selectedCurrency))
                                                            .font(.headline)
                                                            .foregroundColor(.red)
                                                    }
                                                    
                                                    Spacer()
                                                }
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .fill(.ultraThinMaterial)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 6)
                                            )
                                            .padding(.horizontal, 24)
                                            
                                            // Extra space below card so dots don't overlap
                                            Spacer(minLength: 24)
                                        }
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 210)
                                
                                // Custom page indicator with its own background
                                HStack(spacing: 6) {
                                    ForEach(Array(monthlyTotals.indices), id: \.self) { index in
                                        Circle()
                                            .fill(index == selectedMonthIndex ? Color.accentColor : Color.secondary.opacity(0.4))
                                            .frame(width: index == selectedMonthIndex ? 8 : 6,
                                                   height: index == selectedMonthIndex ? 8 : 6)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
                                )
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, -8)
                            }
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
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                                )
                                .padding(.horizontal, 16)
                                
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
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(UIColor.secondarySystemBackground).opacity(0.9))
                                        )
                                    }
                                }
                                .padding(.horizontal, 8)
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
                                    .padding(.vertical, 32)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .padding(.horizontal, 24)
                            } else {
                                ForEach(recentTransactions) { transaction in
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.accentColor.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                                .foregroundColor(transaction.type == .income ? .green : .red)
                                        }
                                        
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
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color(UIColor.secondarySystemBackground).opacity(0.95))
                                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .navigationTitle("Home")
                .onAppear {
                    if !monthlyTotals.isEmpty {
                        selectedMonthIndex = monthlyTotals.count - 1
                    }
                }
            }
        }
    }
}
