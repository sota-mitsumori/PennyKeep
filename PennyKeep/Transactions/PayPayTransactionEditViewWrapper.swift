import SwiftUI

struct PayPayTransactionEditViewWrapper: View {
    let transaction: PayPayTransaction
    let onSave: (PayPayTransaction) -> Void
    let onCancel: () -> Void
    
    @State private var editedTransaction: PayPayTransaction
    
    init(transaction: PayPayTransaction, onSave: @escaping (PayPayTransaction) -> Void, onCancel: @escaping () -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        self.onCancel = onCancel
        _editedTransaction = State(initialValue: transaction)
    }
    
    var body: some View {
        PayPayTransactionEditView(
            transaction: Binding(
                get: { editedTransaction },
                set: { newValue in
                    editedTransaction = newValue
                }
            ),
            onSave: {
                // Save the updated transaction
                onSave(editedTransaction)
            },
            onCancel: onCancel
        )
    }
}
