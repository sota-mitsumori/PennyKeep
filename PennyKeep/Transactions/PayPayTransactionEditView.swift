import SwiftUI

struct PayPayTransactionEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var appSettings: AppSettings
    
    @Binding var transaction: PayPayTransaction
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var editedTitle: String
    @State private var editedCategory: String
    @State private var editedType: TransactionType
    @State private var editedDate: Date
    
    init(transaction: Binding<PayPayTransaction>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._transaction = transaction
        self.onSave = onSave
        self.onCancel = onCancel
        _editedTitle = State(initialValue: transaction.wrappedValue.editedTitle ?? transaction.wrappedValue.displayTitle)
        _editedCategory = State(initialValue: transaction.wrappedValue.editedCategory ?? "Other")
        _editedType = State(initialValue: transaction.wrappedValue.editedType ?? (transaction.wrappedValue.isExpense ? .expense : .income))
        _editedDate = State(initialValue: transaction.wrappedValue.dateTime)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Title", text: $editedTitle)
                    
                    DatePicker("Date", selection: $editedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    Picker("Type", selection: $editedType) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: editedType) {
                        categoryManager.refreshCategories()
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $editedCategory) {
                        if editedType == .expense {
                            ForEach(categoryManager.expenseCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        } else {
                            ForEach(categoryManager.incomeCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Amount")) {
                    Text(abs(transaction.amount), format: .currency(code: appSettings.selectedCurrency))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                categoryManager.refreshCategories()
            }
        }
    }
    
    private func saveChanges() {
        // Update the binding transaction
        var updated = transaction
        updated.editedTitle = editedTitle
        updated.editedCategory = editedCategory
        updated.editedType = editedType
        updated.dateTime = editedDate
        transaction = updated
        
        // Call onSave callback
        onSave()
    }
}
