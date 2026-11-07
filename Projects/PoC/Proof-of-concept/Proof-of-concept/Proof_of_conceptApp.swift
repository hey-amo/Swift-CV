//
//  Proof_of_conceptApp.swift
//  Proof-of-concept
//
//  Created by Amarjit on 07/11/2026.
//

import SwiftUI

// Replace your Playground / Xcode @main file with this, or just use the demo views directly.
// Requires iOS 17+ (Xcode 16 / Swift Playgrounds 4.5+).
@main
struct GestureLabApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    NavigationLink("1 · Briefcase drawer") {
                        InventoryDrawerDemo()
                            .navigationTitle("Briefcase")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    NavigationLink("2 · Two-panel transfer") {
                        TwoPanelTransferDemo()
                            .navigationTitle("Transfer")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    NavigationLink("3 · Gem collect") {
                        GemCollectDemo()
                            .navigationTitle("Gems")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .navigationTitle("Gesture Lab")
            }
        }
    }
}
