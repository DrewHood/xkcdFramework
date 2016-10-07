//
//  Date+Initialization.swift
//  xkcd
//
//  Created by Drew Hood on 9/14/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation

extension Date {
    init(withDateString dateString: String) {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-M-d"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let d = dateFormatter.date(from: dateString)!
        self.init(timeInterval:0, since:d)
    }
}
