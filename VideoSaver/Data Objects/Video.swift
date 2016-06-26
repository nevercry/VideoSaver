//
//  Video.swift
//  VideoSaver
//
//  Created by nevercry on 5/24/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit
import AVFoundation

struct Video {
    var title: String
    var createdDate: NSDate
    var fileSize: NSNumber
    var path: String
    var thumbnail: UIImage?
    
    
    func simpleDescription() -> String {
        return "Video Title is \(title), created at \(createdDate)"
    }
    
    func duration() -> String {
        let avUrl = AVURLAsset(URL: NSURL(fileURLWithPath: path))
        let time = avUrl.duration
        var seconds = Int(time.seconds)
        
        
        let hours   = seconds / 3600
        let minutes = (seconds - (hours * 3600)) / 60;
        seconds = seconds - (hours * 3600) - (minutes * 60);
        var druation = ""
        
        if (hours != 0) {
            druation = "\(hours)"+":";
        }
        if (minutes != 0 || druation != "") {
            let minutesStr = (minutes < 10 && druation != "") ? "0"+"\(minutes)" : String(minutes);
            druation += minutesStr+":";
        }
        if (druation == "") {
            druation = (seconds < 10) ? "0:0"+"\(seconds)" : "0:"+String(seconds);
        }
        else {
            druation += (seconds < 10) ? "0"+"\(seconds)" : String(seconds);
        }
        return druation;
    }
}