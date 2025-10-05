
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
              Text("\(transaction.type == .income ? "+" : "-")\(transaction.amount, format: .currency(code: appSettings.selectedCurrency))")
                  .font(.headline)
                  .foregroundColor(transaction.type == .income ? .green : .red)
         }
         .contentShape(Rectangle())
         .onTapGesture {
             onEdit()
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
