//
//  UIViewController+extension.swift
//  Timebox
//
//  Created by Lianghan Siew on 29/03/2022.
//

import UIKit

extension UIViewController {
    /// Allows centering navigation bar large title
    func centerTitle() {
        for navItem in (self.navigationController?.navigationBar.subviews)! {
             for itemSubView in navItem.subviews {
                 if let largeLabel = itemSubView as? UILabel {
                    largeLabel.center = CGPoint(x: navItem.bounds.width / 2, y: navItem.bounds.height / 2)
                    return;
                 }
             }
        }
    }
}
