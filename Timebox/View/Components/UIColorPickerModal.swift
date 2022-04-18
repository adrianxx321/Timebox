//
//  UIColorPickerModal.swift
//  Timebox
//
//  Created by Lianghan Siew on 28/03/2022.
//

import SwiftUI

// This color picker was created because the default one used in SwiftUI
// Does not allow for dismissal when presented modally
struct UIColorPickerModal: UIViewControllerRepresentable {
    // MARK: UI States
    @Binding var isPresented: Bool
    @Binding var selectedColor: UIColor

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // React on binding
        // Show if not already...
        if isPresented && uiViewController.presentedViewController == nil {
            let controller = UIColorPickerViewController()
            controller.delegate = context.coordinator
            controller.selectedColor = self.selectedColor
            controller.presentationController?.delegate = context.coordinator

            uiViewController.present(controller, animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        let parent: UIColorPickerModal
        
        init(parent: UIColorPickerModal) {
            self.parent = parent
        }
        
        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {

            viewController.selectedColor = color
            parent.selectedColor = viewController.selectedColor
        }
        
        /// Dismiss on tapping close button
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            parent.isPresented = false
        }

        /// Dismiss on swipe
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.isPresented = false
        }
    }
}
