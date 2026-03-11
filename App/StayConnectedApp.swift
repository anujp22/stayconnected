
import CoreData
import SwiftUI

@main
struct StayConnectedApp: App {

    // MARK: - Dependencies
    let persistenceController = PersistenceController.shared
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    // MARK: - App Scene
    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tint(Color("Primary"))
                .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
