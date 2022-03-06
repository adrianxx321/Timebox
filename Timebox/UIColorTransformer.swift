//
//  UIColorTransformer.swift
//  Timebox
//
//  Created by Lianghan Siew on 05/03/2022.
//

import Foundation
import UIKit

class UIColorTransformer: ValueTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        
        guard let color = value as? UIColor else { return nil }
        
        do {
            let encodedData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            return encodedData
        } catch {
            return nil
        }
        
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        
        guard let encodedData = value as? Data else { return nil }
        
        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: encodedData)
            return color
        } catch {
            return nil
        }
        
    }
    
}
