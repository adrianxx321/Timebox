//
//  String+extension.swift
//  Timebox
//
//  Created by Lianghan Siew on 26/03/2022.
//

import SwiftUI

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
