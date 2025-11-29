//
//  ZoomableImageContainer.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

// Shared zoom/pan container powered by UIScrollView for smooth gestures on iOS
// Uses NSScrollView on macOS
struct ZoomableImageContainer<Content: View>: View {
  let screenSize: CGSize
  let resetID: AnyHashable
  let minScale: CGFloat
  let maxScale: CGFloat
  let doubleTapScale: CGFloat
  @Binding var isZoomed: Bool
  @ViewBuilder private let content: () -> Content

  init(
    screenSize: CGSize,
    resetID: AnyHashable,
    minScale: CGFloat = 1.0,
    maxScale: CGFloat = 4.0,
    doubleTapScale: CGFloat = 2.0,
    isZoomed: Binding<Bool> = .constant(false),
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.screenSize = screenSize
    self.resetID = resetID
    self.minScale = minScale
    self.maxScale = maxScale
    self.doubleTapScale = doubleTapScale
    self._isZoomed = isZoomed
    self.content = content
  }

  var body: some View {
    #if canImport(UIKit)
      ZoomableScrollViewRepresentable(
        resetID: resetID,
        minScale: minScale,
        maxScale: maxScale,
        doubleTapScale: doubleTapScale,
        isZoomed: $isZoomed,
        content: content
      )
      .frame(width: screenSize.width, height: screenSize.height)
    #elseif canImport(AppKit)
      ZoomableScrollViewRepresentable(
        resetID: resetID,
        minScale: minScale,
        maxScale: maxScale,
        doubleTapScale: doubleTapScale,
        isZoomed: $isZoomed,
        content: content
      )
      .frame(width: screenSize.width, height: screenSize.height)
    #endif
  }
}

#if canImport(UIKit)
  import UIKit

  private struct ZoomableScrollViewRepresentable<Content: View>: UIViewRepresentable {
    typealias UIViewType = UIScrollView

    let resetID: AnyHashable
    let minScale: CGFloat
    let maxScale: CGFloat
    let doubleTapScale: CGFloat
    var isZoomed: Binding<Bool>
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
      Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIScrollView {
      let scrollView = UIScrollView()
      scrollView.delegate = context.coordinator
      scrollView.minimumZoomScale = minScale
      scrollView.maximumZoomScale = max(maxScale * 1.5, maxScale)
      scrollView.bouncesZoom = true
      scrollView.bounces = true
      scrollView.clipsToBounds = true
      scrollView.showsHorizontalScrollIndicator = false
      scrollView.showsVerticalScrollIndicator = false
      scrollView.contentInsetAdjustmentBehavior = .never
      scrollView.backgroundColor = .clear

      let hostedView = context.coordinator.hostingController.view!
      hostedView.translatesAutoresizingMaskIntoConstraints = false
      hostedView.backgroundColor = .clear
      scrollView.addSubview(hostedView)

      NSLayoutConstraint.activate([
        hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
        hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
        hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
        hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        hostedView.widthAnchor.constraint(
          greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
        hostedView.heightAnchor.constraint(
          greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),
      ])

      context.coordinator.attachDoubleTapRecognizer(to: scrollView)
      context.coordinator.centerContentIfNeeded(scrollView)
      return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
      context.coordinator.parent = self
      context.coordinator.updateContent(with: content())
      scrollView.minimumZoomScale = minScale
      scrollView.maximumZoomScale = max(maxScale * 1.5, maxScale)

      if context.coordinator.lastResetID != resetID {
        context.coordinator.lastResetID = resetID
        context.coordinator.resetZoom(in: scrollView, animated: false)
      }

      context.coordinator.updateZoomState(for: scrollView)
      context.coordinator.centerContentIfNeeded(scrollView)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
      var parent: ZoomableScrollViewRepresentable
      let hostingController: UIHostingController<AnyView>
      var lastResetID: AnyHashable?

      init(parent: ZoomableScrollViewRepresentable) {
        self.parent = parent
        self.hostingController = UIHostingController(rootView: AnyView(parent.content()))
        self.hostingController.view.backgroundColor = .clear
      }

      func updateContent(with view: Content) {
        hostingController.rootView = AnyView(view)
        hostingController.view.setNeedsLayout()
      }

      func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        hostingController.view
      }

      func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContentIfNeeded(scrollView)
        updateZoomState(for: scrollView)
      }

      func scrollViewDidScroll(_ scrollView: UIScrollView) {
        centerContentIfNeeded(scrollView)
      }

      func scrollViewDidEndZooming(
        _ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat
      ) {
        clampScaleIfNeeded(for: scrollView, currentScale: scale)
      }

      func resetZoom(in scrollView: UIScrollView, animated: Bool) {
        scrollView.setZoomScale(parent.minScale, animated: animated)
        scrollView.setContentOffset(.zero, animated: animated)
        centerContentIfNeeded(scrollView)
        updateZoomState(for: scrollView)
      }

      func updateZoomState(for scrollView: UIScrollView) {
        let zoomed = scrollView.zoomScale > (parent.minScale + 0.01)
        guard parent.isZoomed.wrappedValue != zoomed else { return }
        DispatchQueue.main.async { [weak self] in
          self?.parent.isZoomed.wrappedValue = zoomed
        }
      }

      func centerContentIfNeeded(_ scrollView: UIScrollView) {
        let horizontalInset = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let verticalInset = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(
          top: verticalInset,
          left: horizontalInset,
          bottom: verticalInset,
          right: horizontalInset
        )
      }

      func clampScaleIfNeeded(for scrollView: UIScrollView, currentScale: CGFloat) {
        var target = currentScale
        if currentScale < parent.minScale {
          target = parent.minScale
        } else if currentScale > parent.maxScale {
          target = parent.maxScale
        }
        guard abs(target - currentScale) > .ulpOfOne else { return }
        scrollView.setZoomScale(target, animated: true)
      }

      func attachDoubleTapRecognizer(to scrollView: UIScrollView) {
        let recognizer = UITapGestureRecognizer(
          target: self, action: #selector(handleDoubleTap(_:)))
        recognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(recognizer)
      }

      @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let scrollView = recognizer.view as? UIScrollView else { return }
        if scrollView.zoomScale > parent.minScale + 0.01 {
          scrollView.setZoomScale(parent.minScale, animated: true)
        } else {
          let targetScale = min(parent.maxScale, parent.doubleTapScale)
          let point = recognizer.location(in: hostingController.view)
          zoom(to: point, scale: targetScale, in: scrollView)
        }
      }

      private func zoom(to point: CGPoint, scale: CGFloat, in scrollView: UIScrollView) {
        let zoomRect = CGRect(
          x: point.x - scrollView.bounds.size.width / (scale * 2),
          y: point.y - scrollView.bounds.size.height / (scale * 2),
          width: scrollView.bounds.size.width / scale,
          height: scrollView.bounds.size.height / scale
        )
        scrollView.zoom(to: zoomRect, animated: true)
      }
    }
  }

#elseif canImport(AppKit)
  import AppKit

  private struct ZoomableScrollViewRepresentable<Content: View>: NSViewRepresentable {
    typealias NSViewType = NSScrollView

    let resetID: AnyHashable
    let minScale: CGFloat
    let maxScale: CGFloat
    let doubleTapScale: CGFloat
    var isZoomed: Binding<Bool>
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
      Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
      let scrollView = NSScrollView()
      scrollView.hasHorizontalScroller = false
      scrollView.hasVerticalScroller = false
      scrollView.autohidesScrollers = true
      scrollView.borderType = .noBorder
      scrollView.backgroundColor = .clear
      scrollView.drawsBackground = false
      scrollView.allowsMagnification = true
      scrollView.minMagnification = minScale
      scrollView.maxMagnification = max(maxScale * 1.5, maxScale)

      let clipView = scrollView.contentView
      clipView.backgroundColor = .clear

      let hostedView = context.coordinator.hostingController.view
      hostedView.translatesAutoresizingMaskIntoConstraints = false
      hostedView.wantsLayer = true
      hostedView.layer?.backgroundColor = .clear
      clipView.addSubview(hostedView)

      NSLayoutConstraint.activate([
        hostedView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
        hostedView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
        hostedView.topAnchor.constraint(equalTo: clipView.topAnchor),
        hostedView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
        hostedView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor),
        hostedView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),
      ])

      context.coordinator.attachDoubleClickRecognizer(to: scrollView)
      context.coordinator.centerContentIfNeeded(scrollView)
      return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
      context.coordinator.parent = self
      context.coordinator.updateContent(with: content())
      scrollView.minMagnification = minScale
      scrollView.maxMagnification = max(maxScale * 1.5, maxScale)

      if context.coordinator.lastResetID != resetID {
        context.coordinator.lastResetID = resetID
        context.coordinator.resetZoom(in: scrollView, animated: false)
      }

      context.coordinator.updateZoomState(for: scrollView)
      context.coordinator.centerContentIfNeeded(scrollView)
    }

    final class Coordinator: NSObject {
      var parent: ZoomableScrollViewRepresentable
      let hostingController: NSHostingController<AnyView>
      var lastResetID: AnyHashable?

      init(parent: ZoomableScrollViewRepresentable) {
        self.parent = parent
        self.hostingController = NSHostingController(rootView: AnyView(parent.content()))
        self.hostingController.view.wantsLayer = true
        self.hostingController.view.layer?.backgroundColor = .clear
      }

      func updateContent(with view: Content) {
        hostingController.rootView = AnyView(view)
        hostingController.view.needsLayout = true
      }

      func resetZoom(in scrollView: NSScrollView, animated: Bool) {
        scrollView.magnification = parent.minScale
        scrollView.contentView.scroll(to: .zero)
        centerContentIfNeeded(scrollView)
        updateZoomState(for: scrollView)
      }

      func updateZoomState(for scrollView: NSScrollView) {
        let zoomed = scrollView.magnification > (parent.minScale + 0.01)
        guard parent.isZoomed.wrappedValue != zoomed else { return }
        DispatchQueue.main.async { [weak self] in
          self?.parent.isZoomed.wrappedValue = zoomed
        }
      }

      func centerContentIfNeeded(_ scrollView: NSScrollView) {
        let contentSize = scrollView.contentView.documentRect.size
        let scrollViewSize = scrollView.contentView.bounds.size

        let horizontalInset = max((scrollViewSize.width - contentSize.width) / 2, 0)
        let verticalInset = max((scrollViewSize.height - contentSize.height) / 2, 0)

        scrollView.contentView.contentInsets = NSEdgeInsets(
          top: verticalInset,
          left: horizontalInset,
          bottom: verticalInset,
          right: horizontalInset
        )
      }

      func attachDoubleClickRecognizer(to scrollView: NSScrollView) {
        let recognizer = NSClickGestureRecognizer(
          target: self, action: #selector(handleDoubleClick(_:)))
        recognizer.numberOfClicksRequired = 2
        scrollView.addGestureRecognizer(recognizer)
      }

      @objc private func handleDoubleClick(_ recognizer: NSClickGestureRecognizer) {
        guard let scrollView = recognizer.view as? NSScrollView else { return }
        if scrollView.magnification > parent.minScale + 0.01 {
          scrollView.animator().magnification = parent.minScale
        } else {
          let targetScale = min(parent.maxScale, parent.doubleTapScale)
          let point = recognizer.location(in: hostingController.view)
          zoom(to: point, scale: targetScale, in: scrollView)
        }
      }

      private func zoom(to point: NSPoint, scale: CGFloat, in scrollView: NSScrollView) {
        let currentMagnification = scrollView.magnification
        let newMagnification = scale

        // Calculate the zoom point in document coordinates
        let documentPoint = scrollView.contentView.convert(point, from: hostingController.view)

        // Set the magnification
        scrollView.animator().magnification = newMagnification

        // Adjust scroll position to keep the point under the cursor
        let scaleFactor = newMagnification / currentMagnification
        let newPoint = NSPoint(
          x: documentPoint.x * scaleFactor,
          y: documentPoint.y * scaleFactor
        )
        scrollView.contentView.scroll(to: newPoint)
      }
    }
  }
#endif
