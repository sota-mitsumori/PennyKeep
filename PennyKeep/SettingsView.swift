import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    let currencies = ["$", "€", "£", "¥", "₹"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Currency Settings")) {
                    Picker("Currency", selection: $appSettings.selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency)
                        }
                    }
                    .pickerStyle(.automatic)
                }
                Section(header: Text("Version")) {
                    Text("Version 1.2.0 (2025.04.15)")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettings())
    }
}

