import CoreData

// MARK: - Persistence Controller

struct PersistenceController {
    // MARK: - Shared Instance

    static let shared = PersistenceController()

    // MARK: - Preview

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for index in 0..<10 {
            let person = Person(context: viewContext)
            person.id = UUID()
            person.contactIdentifier = "preview-\(index)"
            person.displayName = "Preview Person \(index)"
            person.isInPool = true
        }
        do {
            try viewContext.save()
        } catch {
            // Preview data is disposable; surface the error loudly during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // MARK: - Properties

    let container: NSPersistentContainer

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StayConnected")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // Enable staged lightweight migration explicitly. The store shipped with
        // a single model version; V2 renames DailyPick.contactIdentifiers
        // (Transformable) to contactIdentifiersRaw (String) and relaxes several
        // Person attributes to optional. Lightweight migration handles the
        // optionality and add/remove-attribute changes; the daily picks are
        // regenerated each day, so the dropped Transformable value is harmless.
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
