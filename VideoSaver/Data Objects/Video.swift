//
//  Video.swift
//  VideoSaver
//
//  Created by nevercry on 5/24/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit

struct Video {
    var title: String
    var createdDate: NSDate
    var fileSize: NSNumber
    var path: String
    var thumbnail: UIImage?
    
    func simpleDescription() -> String {
        return "Video Title is \(title), created at \(createdDate)"
    }
}