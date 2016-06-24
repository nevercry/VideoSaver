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
    var fileName: String
    var isDownloading = false
    var progress: Float = 0.0
    
    var downloadTask: NSURLSessionDownloadTask?
    var resumeData: NSData?
    
    init(url: String, fileName: String) {
        self.url = url
        self.fileName = fileName
    }
}
