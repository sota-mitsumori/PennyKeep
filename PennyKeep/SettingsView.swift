import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Option 1")
                Text("Option 2")
            }
            .navigationTitle("Settings")
        }
    }
}


