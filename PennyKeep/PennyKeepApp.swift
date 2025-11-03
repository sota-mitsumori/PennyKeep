import SwiftUI
import SwiftData

@main
struct PennyKeepApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            print("🔧 Creating ModelContainer with CloudKit...")
            
            // Settings to make ModelContainer use CloudKit
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            modelContainer = try ModelContainer(
                for: Transaction.self, Category.self,
                configurations: configuration
            )
            
            print("✅ ModelContainer created successfully with CloudKit")
        } catch {
            print("❌ Failed to create ModelContainer: \(error)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppInitializer(modelContainer: modelContainer)
                .modelContainer(modelContainer)
        }
    }
}
