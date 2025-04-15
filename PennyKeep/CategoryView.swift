import SwiftUI
import Charts

struct Option {
    let name: String
}

struct CategoryChartData: Identifiable {
    var id: String { "\(category)-\(type)" }
    let category: String
    let type: String
    let amount: Double
}


struct MonthlyChartData: Identifiable {
    var id: Date { month }
    let month: Date
    let savedAmount: Double
}

struct CategoryView : View {
    @EnvironmentObject var transactionStore : TransactionStore
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var categoryManager: CategoryManager
    
    @State private var selectedOption : Int = 0
    
    let options = [
        Option(name: "Expense"), Option(name: "Income"), Option(name: "Amount Saved"),
    ]
    
    var chartData: [CategoryChartData] {
        var data: [CategoryChartData] = []
        let categories = Set(transactionStore.transactions.map { $0.category })
        for category in categories {
            let transactionsForCategory = transactionStore.transactions.filter { $0.category == category }
            let expenseTotal = transactionsForCategory.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let incomeTotal = transactionsForCategory.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            data.append(CategoryChartData(category: category, type: "Expense", amount: expenseTotal))
            data.append(CategoryChartData(category: category, type: "Income", amount: incomeTotal))
        }
        return data
    }
    
    var monthlySavedData: [MonthlyChartData] {
        let grouped = Dictionary(grouping: transactionStore.transactions) { transaction in
             Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: transaction.date))!
        }
        let data = grouped.map { (month, transactions) in
             let expenseTotal = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
             let incomeTotal = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
             return MonthlyChartData(month: month, savedAmount: incomeTotal - expenseTotal)
        }
        return data.sorted { $0.month < $1.month }
    }
    
    var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    var availableMonths: [Date] {
        let months = transactionStore.transactions.map {
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: $0.date))!
        }
        return Array(Set(months)).sorted()
    }
    
    func chartData(for month: Date) -> [CategoryChartData] {
        let transactionsForMonth = transactionStore.transactions.filter {
            Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month)
        }
        var data: [CategoryChartData] = []
        let categories = Set(transactionsForMonth.map { $0.category })
        for category in categories {
            let transactionsForCategory = transactionsForMonth.filter { $0.category == category }
            switch selectedOption {
            case 0: // Expense
                let expenseTotal = transactionsForCategory.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                data.append(CategoryChartData(category: category, type: "Expense", amount: expenseTotal))
            case 1: // Income
                let incomeTotal = transactionsForCategory.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                data.append(CategoryChartData(category: category, type: "Income", amount: incomeTotal))
            default:
                break
            }
        }
        return data
    }
    
    var filteredChartData: [CategoryChartData] {
        switch selectedOption {
        case 0: // Expense
            return chartData.filter { $0.type == "Expense" && categoryManager.expenseCategories.contains($0.category)}
        case 1: // Income
            return chartData.filter { $0.type == "Income" && categoryManager.incomeCategories.contains($0.category)}
        case 2: // Amount Saved
            var data: [CategoryChartData] = []
            let categories = Set(transactionStore.transactions.map { $0.category })
            for category in categories {
                let transactionsForCategory = transactionStore.transactions.filter { $0.category == category }
                let expenseTotal = transactionsForCategory.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                let incomeTotal = transactionsForCategory.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let saved = incomeTotal - expenseTotal
                data.append(CategoryChartData(category: category, type: "Amount Saved", amount: saved))
            }
            return data
        default:
            return chartData
        }
    }
    
    
    var body : some View {
        NavigationView {
            VStack {
                Section {
                    Picker("Select the option", selection: $selectedOption) {
                        ForEach(0..<options.count, id: \.self) {index in Text(options[index].name).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }
                
                if selectedOption == 2 {
                    Chart(monthlySavedData) { item in
                         BarMark(
                              x: .value("Month", item.month, unit: .month),
                              y: .value("Amount Saved", item.savedAmount)
                         )
                    }
                    .chartXAxis {
                         AxisMarks(values: .automatic)
                    }
                    .padding()
                } else {
                    TabView {
                        ForEach(availableMonths, id: \.self) { month in
                            VStack {
                                Text(monthFormatter.string(from: month))
                                    .font(.headline)
                                Chart(chartData(for: month).filter { $0.amount != 0 }) { item in
                                    SectorMark(
                                        angle: .value("Amount", item.amount),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 2
                                    )
                                    .cornerRadius(5)
                                    .foregroundStyle(by: .value("Category", item.category))
                                }
                                .chartLegend(alignment: .center, spacing: 16)
                                .padding()
                                
                                // New list of categories with amount spent
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(chartData(for: month).filter { $0.amount != 0 }) { item in
                                        HStack {
                                            Text(item.category)
                                            Spacer()
                                            if appSettings.selectedCurrency == "¥" {
                                                Text("¥\(item.amount, specifier: "%.0f")")
                                            } else {
                                                Text("\(appSettings.selectedCurrency)\(item.amount, specifier: "%.2f")")

                                            }
                                            
                                        }
                                        .padding()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Categories")
        }
    }
}
