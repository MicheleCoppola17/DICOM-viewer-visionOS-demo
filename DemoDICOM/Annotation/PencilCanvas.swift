//
//  PencilCanvas.swift
//  DemoDICOM
//

import SwiftUI
import UIKit

// MARK: - PencilCanvasState

/// Observable object that bridges UIKit stroke state to SwiftUI.
/// `AnnotationView` holds one as `@State` and uses it to drive
/// the undo / clear toolbar buttons and to check whether strokes exist.
@Observable
final class PencilCanvasState {

    /// Number of completed strokes — drives toolbar button enabled states.
    private(set) var strokeCount: Int = 0

    /// Weak reference to the underlying UIView, set by the representable.
    fileprivate weak var canvasView: PencilCanvasUIView? {
        didSet { syncCount() }
    }

    func undo() {
        canvasView?.undo()
        syncCount()
    }

    func clear() {
        canvasView?.clear()
        syncCount()
    }

    private func syncCount() {
        strokeCount = canvasView?.strokeCount ?? 0
    }

    /// Called by the UIView whenever a stroke is completed.
    fileprivate func strokeCompleted() {
        strokeCount = canvasView?.strokeCount ?? 0
    }
}

// MARK: - PencilCanvasUIView

/// UIView that captures Apple Pencil Pro touches and renders strokes
/// as `CAShapeLayer`s — one per completed stroke, for easy undo.
final class PencilCanvasUIView: UIView {

    // MARK: Public settings (updated by the representable on SwiftUI re-render)

    var brushColor: UIColor = .red   { didSet { /* affects next stroke only */ } }
    var brushSize:  CGFloat = 3.0

    /// How many completed strokes are stored (used by `PencilCanvasState`).
    private(set) var strokeCount: Int = 0

    // MARK: Callbacks

    var onStrokeCompleted: (() -> Void)?

    // MARK: Private state

    private var strokeLayers:  [CAShapeLayer] = []
    private var currentPath:   UIBezierPath?
    private var currentLayer:  CAShapeLayer?

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Public API

    func undo() {
        guard let last = strokeLayers.popLast() else { return }
        last.removeFromSuperlayer()
        strokeCount = strokeLayers.count
    }

    func clear() {
        strokeLayers.forEach { $0.removeFromSuperlayer() }
        strokeLayers = []
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        currentPath  = nil
        strokeCount  = 0
    }

    // MARK: Touch handling — Apple Pencil Pro only

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch.type == .pencil else { return }

        let point = touch.location(in: self)
        let path  = UIBezierPath()
        path.move(to: point)
        currentPath = path

        let shapeLayer = makeShapeLayer()
        layer.addSublayer(shapeLayer)
        currentLayer = shapeLayer
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch.type == .pencil,
              let path = currentPath else { return }

        // Coalesced touches give higher-resolution input with lower latency
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        for sample in samples {
            path.addLine(to: sample.location(in: self))
        }
        currentLayer?.path = path.cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch.type == .pencil else { return }
        finaliseStroke()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Discard the in-progress stroke on cancellation
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        currentPath  = nil
    }

    // MARK: Private helpers

    private func makeShapeLayer() -> CAShapeLayer {
        let sl = CAShapeLayer()
        sl.strokeColor = brushColor.cgColor
        sl.lineWidth   = brushSize
        sl.lineCap     = .round
        sl.lineJoin    = .round
        sl.fillColor   = UIColor.clear.cgColor
        return sl
    }

    private func finaliseStroke() {
        guard let layer = currentLayer else { return }
        strokeLayers.append(layer)
        strokeCount = strokeLayers.count
        currentLayer = nil
        currentPath  = nil
        onStrokeCompleted?()
    }
}

// MARK: - PencilCanvas (UIViewRepresentable)

/// SwiftUI wrapper around `PencilCanvasUIView`.
///
/// - `state` is an `@Observable` object owned by `AnnotationView`.
///   The representable wires the UIView into it so that SwiftUI can
///   call `state.undo()` / `state.clear()` from toolbar buttons.
struct PencilCanvas: UIViewRepresentable {

    /// Shared state object — owned by `AnnotationView`.
    let state: PencilCanvasState

    /// Current brush settings, passed down on every SwiftUI re-render.
    let brushColor: Color
    let brushSize:  CGFloat

    func makeUIView(context: Context) -> PencilCanvasUIView {
        let view = PencilCanvasUIView()
        // Wire the UIView back into the observable state object
        state.canvasView = view
        view.onStrokeCompleted = { [weak state] in
            state?.strokeCompleted()
        }
        return view
    }

    func updateUIView(_ uiView: PencilCanvasUIView, context: Context) {
        uiView.brushColor = UIColor(brushColor)
        uiView.brushSize  = brushSize
    }
}
