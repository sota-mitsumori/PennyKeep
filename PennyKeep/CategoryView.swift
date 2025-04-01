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

struct CategoryView : View {
    @EnvironmentObject var transactionStore : TransactionStore
    @EnvironmentObject var categoryStore : AppSettings
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
    
    var filteredChartData: [CategoryChartData] {
        switch selectedOption {
        case 0: // Expense
            return chartData.filter { $0.type == "Expense" }
        case 1: // Income
            return chartData.filter { $0.type == "Income" }
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
                
                Chart(filteredChartData) { item in
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
            }
            .navigationTitle("Categories")
        }
    }
}
