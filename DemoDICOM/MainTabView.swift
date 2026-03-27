//
//  MainTabView.swift
//  DemoDICOM
//

import SwiftUI

/// Root tab container shown once the SharePlay session has started (or in solo mode).
///
/// Uses `.sidebarAdaptable` which renders as a compact sidebar ornament on visionOS,
/// giving access to the DICOM viewer and the saved annotations library.
struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Viewer", systemImage: "doc.viewfinder") {
                ContentView()
            }
            Tab("Annotations", systemImage: "pencil.and.list.clipboard") {
                SavedAnnotationsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
