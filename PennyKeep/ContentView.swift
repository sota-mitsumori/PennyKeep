import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            TransactionsView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Transactions")
                }
            
            CategoryView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("Category")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CategoryManager())
            .environmentObject(TransactionStore())
            .environmentObject(AppSettings())
            .environmentObject(AuthenticationManager())
    }
}


