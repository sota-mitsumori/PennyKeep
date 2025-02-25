import SwiftUI

struct CategoryManagerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var categoryManager: CategoryManager
    var transactionType: TransactionType
    @State private var newCategory: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if transactionType == .expense {
                       ForEach(categoryManager.expenseCategories, id: \.self) { category in
                           Text(category)
                       }
                       .onDelete(perform: categoryManager.deleteExpenseCategory)
                       .onMove(perform: categoryManager.moveExpenseCategory)
                    } else {
                       ForEach(categoryManager.incomeCategories, id: \.self) { category in
                           Text(category)
                       }
                       .onDelete(perform: categoryManager.deleteIncomeCategory)
                       .onMove(perform: categoryManager.moveIncomeCategory)
                    }
                }
                
                HStack {
                    TextField("New Category", text: $newCategory)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add") {
                        if transactionType == .expense {
                            categoryManager.addExpenseCategory(newCategory)
                        } else {
                            categoryManager.addIncomeCategory(newCategory)
                        }
                        newCategory = ""
                    }
                    .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Manage Categories")
            .navigationBarItems(leading: EditButton(), trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct CategoryManagerView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryManagerView(transactionType: .expense)
            .environmentObject(CategoryManager())
    }
}

