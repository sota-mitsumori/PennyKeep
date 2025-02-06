import SwiftUI

struct CategoryManagerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var newCategory: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(categoryManager.categories, id: \.self) { category in
                        Text(category)
                    }
                    .onDelete(perform: categoryManager.delete)
                    .onMove(perform: categoryManager.move)
                }
                
                HStack {
                    TextField("New Category", text: $newCategory)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        categoryManager.add(category: newCategory)
                        newCategory = ""
                    }) {
                        Text("Add")
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
        CategoryManagerView()
            .environmentObject(CategoryManager())
    }
}

