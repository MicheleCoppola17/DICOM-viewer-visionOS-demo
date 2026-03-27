//
//  AnnotationView.swift
//  DemoDICOM
//

import SwiftUI

/// A dedicated 2-D annotation window opened from the slice viewer.
///
/// The user opens this window by pinching and holding on the CT scan image.
/// Drawing is done with Apple Pencil Pro directly on the window surface.
/// Strokes are captured via UITouch events (type == .pencil) and rendered
/// as CAShapeLayers for smooth, low-latency inking.
struct AnnotationView: View {

    @Environment(DICOMStore.self) private var store

    @State private var canvasState = PencilCanvasState()
    @State private var brushColor: Color   = .red
    @State private var brushSize:  CGFloat = 3.0

    var body: some View {
        NavigationStack {
            contentArea
                .navigationTitle(
                    "Annotate — Slice \(store.currentSliceIndex + 1) / \(store.sliceCount)"
                )
                .toolbar { toolbarContent }
        }
    }

    // MARK: - Content area

    @ViewBuilder
    private var contentArea: some View {
        if let cgImage = store.currentSliceImage {
            Image(decorative: cgImage, scale: 1.0)
                .resizable()
                .scaledToFit()
                // Pencil canvas overlaid exactly on the image bounds
                .overlay {
                    PencilCanvas(
                        state:      canvasState,
                        brushColor: brushColor,
                        brushSize:  brushSize
                    )
                }
                // Usage hint — fades once a stroke has been drawn
                .overlay(alignment: .bottom) {
                    if canvasState.strokeCount == 0 {
                        Text("Draw with Apple Pencil Pro")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 12)
                    }
                }
                .padding()
        } else {
            ContentUnavailableView(
                "No slice loaded",
                systemImage: "doc.viewfinder",
                description: Text("Import a DICOM folder in the main viewer first.")
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {

        ToolbarItemGroup(placement: .topBarLeading) {
            // Brush colour
            ColorPicker("Color", selection: $brushColor, supportsOpacity: false)
                .labelsHidden()

            // Brush size
            HStack(spacing: 8) {
                Image(systemName: "pencil.tip")
                    .foregroundStyle(.secondary)
                Slider(value: $brushSize, in: 1...20, step: 1)
                    .frame(width: 120)
                Text("\(Int(brushSize)) pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            // Undo last stroke
            Button {
                canvasState.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(canvasState.strokeCount == 0)

            // Clear all strokes
            Button(role: .destructive) {
                canvasState.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .disabled(canvasState.strokeCount == 0)
        }
    }
}
