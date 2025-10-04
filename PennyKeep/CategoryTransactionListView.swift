import SwiftUI

struct CategoryTransactionListView: View {
    let category: String
    let transactions: [Transaction]
    
    @State private var transactionToEdit: Transaction?
    @State private var isPresentingAddTransaction = false
    @State private var scannedData: (title: String, amount: String, date: Date)? = nil

    var body: some View {
        List {
            ForEach(transactions) { transaction in
                TransactionRow(transaction: transaction, onEdit: {
                    transactionToEdit = transaction
                    isPresentingAddTransaction = true
                })
            }
        }
        .navigationTitle(category)
        .sheet(isPresented: $isPresentingAddTransaction) {
            AddTransactionView(transactionToEdit: transactionToEdit, scannedData: $scannedData)
        }
    }
}
