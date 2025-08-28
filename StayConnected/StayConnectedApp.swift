//
//  StayConnectedApp.swift
//  StayConnected
//
//  Created by Anuj Patel on 8/27/25.
//

import SwiftUI

@main
struct StayConnectedApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
