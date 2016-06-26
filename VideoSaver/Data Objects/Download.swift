//
//  Download.swift
//  VideoSaver
//
//  Created by nevercry on 5/29/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit

class Download: NSObject {
    
    var url: String
    var title: String
    var duration: String
    var poster: String
    var source: String
    var isDownloading = false
    var progress: Float = 0.0
    var image: UIImage?
    
    var downloadTask: NSURLSessionDownloadTask?
    var resumeData: NSData?
    
    init(videoInfo: [String: String]) {
        self.url = videoInfo["url"]!
        self.title = videoInfo["title"]!
        self.duration = videoInfo["duration"]!
        self.poster = videoInfo["poster"]!
        self.source = videoInfo["source"]!
    }
}
