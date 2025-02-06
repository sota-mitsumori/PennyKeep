import SwiftUI

struct ExpensesView: View {
    @State private var isPresentingAddExpense = false
    @EnvironmentObject var expenseStore: ExpenseStore
    @State private var selectedDate: Date = Date() // Currently selected date from the calendar
    
    // Filter expenses to only those on the selected date
    var filteredExpenses: [Expense] {
        expenseStore.expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Calendar view on top for date selection
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding([.horizontal, .top])
                
                // Display expenses filtered by the selected date
                if filteredExpenses.isEmpty {
                    Spacer()
                    Text("No expenses for this day")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredExpenses) { expense in
                            VStack(alignment: .leading) {
                                Text(expense.title)
                                    .font(.headline)
                                Text(String(format: "$%.2f", expense.amount))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingAddExpense = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // Present a sheet when the plus button is tapped.
            .sheet(isPresented: $isPresentingAddExpense) {
                AddExpenseView()
                    .environmentObject(expenseStore)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        ExpensesView()
            .environmentObject(ExpenseStore())
    }
}


