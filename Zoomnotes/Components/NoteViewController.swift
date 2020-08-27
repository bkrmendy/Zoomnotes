//
//  NoteViewController.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 08. 13..
//  Copyright © 2020. Berci. All rights reserved.
//

import UIKit
import PencilKit

class NoteViewController : UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!
    
    var toolPicker: PKToolPicker!
    
    var dataModelController: DataModelController!
    var note: NoteModel.NoteLevel!
    var hasModifiedDrawing = false
    
    var subLevelViews: [UUID : NoteLevelPreview] = [:]
    
    // TODO: tool here
    var currentlyDraggedLevel: NoteModel.NoteLevel? = nil
    var zoomOffset: CGPoint? = nil
    
    var interactionController: UIPercentDrivenInteractiveTransition? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.delegate = self
        
        canvasView.delegate = self
        canvasView.drawing = note.data.drawing
        canvasView.alwaysBounceVertical = true
        
        canvasView.isScrollEnabled = true
        
//        #if DEBUG
//            canvasView.allowsFingerDrawing = true
//        #else

//        #endif
        
        canvasView.allowsFingerDrawing = false
        
        let window = parent?.view.window
        toolPicker = PKToolPicker.shared(for: window!)
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        
        updateLayout(for: toolPicker)
        
        canvasView.becomeFirstResponder()
        
        self.view.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        if isMovingToParent || isBeingDismissed {
            for note in note.children.values {
                let sublevel = sublevelPreview(for: note)
                subLevelViews[note.id] = sublevel
                self.canvasView.addSubview(sublevel)
            }
            
            self.view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(onPreviewZoomUp(_:))))
        }
        
        for note in note.children.values {
            subLevelViews[note.id]?.image = note.previewImage.image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        let edgeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped(_:)))
        edgeGestureRecognizer.edges = .right
        edgeGestureRecognizer.delegate = self
        
        self.view.addGestureRecognizer(edgeGestureRecognizer)
        
        let zoomGestureRecognizer = UIPinchGestureRecognizer(target: self,
                                                             action: #selector(onPinch(_:)))
        self.view.addGestureRecognizer(zoomGestureRecognizer)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if hasModifiedDrawing {
            updateLevel()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    @objc func screenEdgeSwiped(_ rec: UIScreenEdgePanGestureRecognizer) {
        let loc = rec.location(in: canvasView)
        let width = self.view.frame.width / 4
        let height = self.view.frame.height / 4
        let frame = CGRect(x: loc.x - width / 2,
                           y: loc.y - height / 2,
                           width: width,
                           height: height)
        
        hasModifiedDrawing = true
        
        if rec.state == .changed {
            if currentlyDraggedLevel == nil {
                let defaultPreviewImage = UIImage.from(frame: view.frame).withBackground(color: UIColor.white)
                
                let newLevel = NoteModel.NoteLevel.default(preview: defaultPreviewImage, frame: frame)
                self.note.children[newLevel.id] = newLevel
                
                let noteLevelPreview = sublevelPreview(for: newLevel)
                self.subLevelViews[newLevel.id] = noteLevelPreview
                
                canvasView.addSubview(noteLevelPreview)
                currentlyDraggedLevel = newLevel
            }
            
            currentlyDraggedLevel!.frame = frame
            subLevelViews[currentlyDraggedLevel!.id]!.frame = frame
        }
        
        if rec.state == .ended {
            subLevelViews[currentlyDraggedLevel!.id]!.frame = frame
            currentlyDraggedLevel!.frame = frame
            currentlyDraggedLevel = nil
        }
    }
    
    @objc func onPinch(_ rec: UIPinchGestureRecognizer) { }
    
    @objc func previewPanGesture(_ rec: UIPanGestureRecognizer,
                                 _ preview: NoteLevelPreview,
                                 onChanged: @escaping (UIPanGestureRecognizer) -> Void,
                                 onEnded: @escaping () -> Void
    ) {
        let velocity = rec.velocity(in: self.view)
        
        print(canvasView.contentOffset)
        
        hasModifiedDrawing = true
        
        let loc = rec.location(in: self.canvasView)
        let relativeLoc = rec.location(in: preview)
        let frame = CGRect(x: loc.x,
                           y: loc.y,
                           width: preview.frame.width,
                           height: preview.frame.height)
        
        preview.frame = frame
        
        if rec.state == .changed {
            onChanged(rec)
            
        } else if rec.state == .ended {
            // MARK: begin snippet
            /// https://www.raywenderlich.com/1860-uikit-dynamics-and-swift-tutorial-tossing-views
            
            let magnitude: CGFloat = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            
            let threshold: CGFloat = 5000
            let velocityPadding: CGFloat  = 35
            
            if magnitude > threshold {
                let animator = UIDynamicAnimator(referenceView: self.view)
                let pushBehavior = UIPushBehavior(items: [preview], mode: .instantaneous)
                pushBehavior.pushDirection = CGVector(dx: velocity.x / 10, dy: velocity.y / 10)
                pushBehavior.magnitude = magnitude / velocityPadding
                
                animator.addBehavior(pushBehavior)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    animator.removeAllBehaviors()
                    onEnded()
                }
            }
            
            // MARK: end snippet
        }
    }
    
    private func onPreviewZoomDown(_ rec: ZNPinchGestureRecognizer, _ note: NoteModel.NoteLevel) {
        if rec.state == .began {
            self.zoomOffset = CGPoint(x: view.bounds.midX - canvasView.contentOffset.x - note.frame.midX,
                                      y: view.bounds.midY - note.frame.midY)
        }
        
        if rec.state == .changed {
            // TODO: Update 4 to calculated value (view width / preview width)
            // needs state
            let scale = clamp(rec.scale, lower: 1, upper: 4)
            view.transform = zoomDownTransform(at: scale, for: self.zoomOffset!)
        }
        
        if rec.state == .ended {
            self.zoomOffset = nil
            guard rec.scale > 1.5 else {
                UIView.animate(withDuration: 0.1) {
                    self.view.transform = .identity
                }
                return
            }
        
            guard let noteViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: NoteViewController.self)) as? NoteViewController,
                let navigationController = navigationController else {
                    return
            }
            
            noteViewController.dataModelController = self.dataModelController
            noteViewController.note = note
            navigationController.pushViewController(noteViewController, animated: false)
        }
    }
    
    @objc func onPreviewZoomUp(_ rec: ZNPinchGestureRecognizer) {
        if rec.state == .began {
            self.interactionController = UIPercentDrivenInteractiveTransition()
            navigationController?.popViewController(animated: true)
        }

        if rec.state == .changed {
            let percent = clamp(1 - rec.scale, lower: 0, upper: 1)
            interactionController?.update(percent)
        }

        if rec.state == .ended {
            if rec.scale < 0.5 && rec.state != .cancelled {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
            }
            interactionController = nil
        }
    }
    
    private func updateContentSizeForDrawing() {
        let drawing = canvasView.drawing
        let contentHeight: CGFloat
    
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY * 1.2) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        canvasView.contentSize = CGSize(width: view.bounds.width * canvasView.zoomScale, height: contentHeight)
    }
    
    private func updateLevel() {
        note.data.drawing = canvasView.drawing
        let screen = captureCurrentScreen()
        note.previewImage = NoteImage(wrapping: screen)
        dataModelController.updatePreview()
    }
    
    private func sublevelPreview(for sublevel: NoteModel.NoteLevel) -> NoteLevelPreview {
        let preview = NoteLevelPreview(for: sublevel)
        
        let panGestureRecognizer = ZNPanGestureRecognizer { rec in
            self.previewPanGesture(rec, preview, onChanged: { rec in
                let loc = rec.location(in: self.canvasView)
                let relativeLoc = rec.location(in: preview)
                sublevel.frame = CGRect(x: loc.x,
                                       y: loc.y,
                                       width: sublevel.frame.width,
                                       height: sublevel.frame.height)
                self.hasModifiedDrawing = true
            }, onEnded: {
                preview.removeFromSuperview()
                self.note.children.removeValue(forKey: sublevel.id)
            })
        }
        
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.minimumNumberOfTouches = 1
        
        preview.addGestureRecognizer(panGestureRecognizer)
        
        preview.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:))))
        
        preview.addGestureRecognizer(ZNPinchGestureRecognizer { rec in
            self.onPreviewZoomDown(rec, sublevel)
        })
        
        return preview
    }
    
    private func captureCurrentScreen() -> UIImage {
        UIGraphicsBeginImageContext(view.frame.size)
        let context = UIGraphicsGetCurrentContext()!
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func setNewDrawingUndoable(_ newDrawing: PKDrawing) {
        let oldDrawing = canvasView.drawing
        undoManager?.registerUndo(withTarget: self) {
            $0.setNewDrawingUndoable(oldDrawing)
        }
        canvasView.drawing = newDrawing
    }
    
    func updateLayout(for toolPicker: PKToolPicker) {
        let obscuredFrame = toolPicker.frameObscured(in: view)
        
        if obscuredFrame.isNull {
            canvasView.contentInset = .zero
            navigationItem.rightBarButtonItems = []
        } else {
            canvasView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.maxY - obscuredFrame.minY, right: 0)
            navigationItem.rightBarButtonItems = [undoButton, redoButton]
        }
        
        canvasView.scrollIndicatorInsets = canvasView.contentInset
    }
}

extension NoteViewController : PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        hasModifiedDrawing = true
        updateContentSizeForDrawing()
    }
    
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
    
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
}

extension NoteViewController : PKToolPickerObserver {
    
}

extension NoteViewController : UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .pop {
            return ZoomTransitionAnimator(with: note)
        }
        return nil
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}
