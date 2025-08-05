import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Currency")) {
                    Picker("Currency", selection: $appSettings.selectedCurrency) {
                        ForEach(currencyItems) { item in
                            Text("\(item.code) – \(item.name)")
                                .tag(item.code)
                        }
                    }
                    .pickerStyle(.automatic)
                }
                Section(header: Text("Version")) {
                    Text("Version 1.3.0 (2025.08.05)")
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
