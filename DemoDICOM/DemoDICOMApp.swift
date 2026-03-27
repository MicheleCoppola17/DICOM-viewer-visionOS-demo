//
//  DemoDICOMApp.swift
//  DemoDICOM
//
//  Created by Michele Coppola on 25/03/2026.
//

import SwiftUI
import GroupActivities

@main
struct DemoDICOMApp: App {

    /// Single source of truth — lives for the entire app lifetime.
    @State private var store = DICOMStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }

        // 2-D annotation window.
        // Opened from ContentView when the user pinches and holds on the CT slice.
        WindowGroup(id: "annotation") {
            AnnotationView()
                .environment(store)
        }
        .defaultSize(width: 720, height: 780)

        // Mixed-immersion drawing space.
        // Opened/dismissed from ContentView via openImmersiveSpace / dismissImmersiveSpace.
        ImmersiveSpace(id: "DrawingSpace") {
            ImmersiveDrawingView()
                .environment(store)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
