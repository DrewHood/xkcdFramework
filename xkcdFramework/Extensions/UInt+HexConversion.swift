//
//  UInt+HexConversion.swift
//  xkcd
//
//  Created by Drew Hood on 9/22/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation

extension UInt {
    init?(_ string: String, radix: UInt) {
        let digits = "0123456789abcdefghijklmnopqrstuvwxyz"
        var result = UInt(0)
        for digit in string.characters {
            if let range = digits.range(of: String(digit)) {
                let val = UInt(digits.distance(from: digits.startIndex, to: range.lowerBound))
                if val >= radix {
                    return nil
                }
                result = result * radix + val
            } else {
                return nil
            }
        }
        self = result
    }
}
