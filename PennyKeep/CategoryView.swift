import SwiftUI

struct Option {
    let name: String
}

struct CategoryView : View {
    @EnvironmentObject var transactionStore : TransactionStore
    @EnvironmentObject var categoryStore : AppSettings
    
    @State private var selectedOption : Int = 0
    
    let options = [
        Option(name: "Expense"), Option(name: "Income"), Option(name: "Amount Saved"),
    ]
    
    var body : some View {
        NavigationView {
            Section {
                Picker("Select the option", selection: $selectedOption) {
                    ForEach(0..<options.count, id: \.self) {index in Text(options[index].name).tag(index)
                    }
                }.pickerStyle(.segmented)
            }
            .navigationTitle("Categories")
        }
    }
}
