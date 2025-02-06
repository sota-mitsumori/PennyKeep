import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var categoryManager: CategoryManager  // Shared categories
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory = "Transportation" // Default
    @State private var expenseDate: Date = Date()
    @State private var isPresentingCategoryManager = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categoryManager.categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    // Button to manage the list of categories.
                    Button("Manage Categories") {
                        isPresentingCategoryManager = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if let expenseAmount = Double(amount), !title.isEmpty {
                        let newExpense = Expense(
                            title: title,
                            amount: expenseAmount,
                            date: expenseDate,
                            category: selectedCategory
                        )
                        expenseStore.expenses.append(newExpense)
                    }
                    dismiss()
                }
            )
            .sheet(isPresented: $isPresentingCategoryManager) {
                CategoryManagerView()  // This view will use the shared categoryManager.
                    .environmentObject(categoryManager)
            }
        }
    }
}

struct AddExpenseView_Previews: PreviewProvider {
    @State static var previewExpenses: [Expense] = []
    
    static var previews: some View {
        AddExpenseView()
            .environmentObject(CategoryManager())
            .environmentObject(ExpenseStore())
    }
}

