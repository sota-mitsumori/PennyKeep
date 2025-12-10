import SwiftUI
import SwiftData

@main
struct PennyKeepApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            print("🔧 Creating ModelContainer...")
            
            // Local storage only (Supabase handles cloud sync)
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: Transaction.self, Category.self,
                configurations: configuration
            )
            
            print("✅ ModelContainer created successfully")
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
