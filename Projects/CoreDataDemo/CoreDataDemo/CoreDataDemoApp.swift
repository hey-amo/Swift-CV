//
//  CoreDataDemoApp.swift
//  CoreDataDemo
//
//  Created by Amarjit on 13/11/2025.
//

import SwiftUI

@main
struct CoreDataDemoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
