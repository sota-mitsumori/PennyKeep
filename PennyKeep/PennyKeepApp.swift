import SwiftUI
import SwiftData

@main
struct PennyKeepApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Transaction.self, Category.self)
        } catch {
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
