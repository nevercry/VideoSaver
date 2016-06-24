//
//  ShareViewController.swift
//  VideoExtension
//
//  Created by nevercry on 5/18/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit
import MobileCoreServices


class ShareViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate{
    
    
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var pinView: UIActivityIndicatorView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    
    var isDownLoading = false {
        didSet {
            setupNetWorkingStats()
        }
    }
    var videoURL: NSURL?
    var pageUrl: NSString?
    var videoType: NSString?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height)
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.transform = CGAffineTransformIdentity
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isDownLoading = false
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = item.attachments?.first as? NSItemProvider {
                let propertyList = String(kUTTypePropertyList)
                if itemProvider.hasItemConformingToTypeIdentifier(propertyList) {
                    itemProvider.loadItemForTypeIdentifier(propertyList, options: nil, completionHandler: { (diction, error) in
                        if let shareDic = diction as? NSDictionary {
                            if let results = shareDic.objectForKey(NSExtensionJavaScriptPreprocessingResultsKey) as? NSDictionary {
                                self.pageUrl = results.objectForKey("url") as? NSString // 网站地址
                                self.videoType = results.objectForKey("videoType") as? NSString // 视频类型
                                print("url is \(self.pageUrl)，videoType is \(self.videoType)")
                                
                                let videoURLStr = results.objectForKey("videoURL") as? NSString // 视频地址
                                if let _ = videoURLStr {
                                    // 如果获取到视频地址
                                    print("video url is \(videoURLStr!)")
                                    if videoURLStr!.length > 0 {
                                        self.videoURL = NSURL(string: videoURLStr! as String)
                                        // 设置文件名
                                        self.title = self.videoURL!.lastPathComponent!
                                    }
                                }
                            }
                        }
                    })
                }
            }
            print("分享内容是: \(item.attributedContentText?.string)")
        }
    }
    
    // MARK: - 添加到下载列表
    @IBAction func saveToDownLoadList(sender: UIBarButtonItem) {
        
        // 找不到shareUrl 提示用户无法使用插件
        // 禁止用户下载
        guard (self.videoURL != nil) else {
            self.downloadButton.enabled = false
            let alC = UIAlertController.init(title: "无法获取视频地址", message: "请先点击播放才能在浏览器中获得视频网址", preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
                self.hideExtensionWithCompletionHandler({ (Bool) -> Void in
                    self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
                })
                
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
            return
        }
        
        // 解析一下是否是优酷的m3u8 文件
        if (videoType == "m3u8") {
            // dataTask;
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.timeoutIntervalForRequest = 10
            let session = NSURLSession(configuration: config)
            session.dataTaskWithRequest(NSURLRequest(URL: videoURL!), completionHandler: { (data, res, error) in
                if ((data) != nil) {
                    let dataInfo = String(data: data!, encoding: NSUTF8StringEncoding)
                    print("dataInfo is \(dataInfo)")
                    let scaner = NSScanner(string: dataInfo!)
                    scaner.scanUpToString("http", intoString: nil)
                    var video_url:NSString?
                    scaner.scanUpToString(".ts", intoString: &video_url)
                    print("videoURL is \(video_url)")
                    if let _ = video_url {
                        self.videoURL = NSURL(string: (video_url as? String)!)
                        dispatch_async(dispatch_get_main_queue(), { 
                            self.startSave()
                            
                        })
                        return
                    }
                }
                
                let alC = UIAlertController.init(title: "无法保存", message: "保存失败", preferredStyle: .Alert)
                let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: nil)
                alC.addAction(cancelAction)
                self.presentViewController(alC, animated: true, completion: nil)
            }).resume()
        } else {
            startSave()
        }
    }
    
    func startSave() {
        let newDownloadTask = ["fileName":fileNameFromURL(self.videoURL!),"url":self.videoURL!.absoluteString]
        saveTask(newDownloadTask)
        hideExtensionWithCompletionHandler { (Bool) -> Void in
            self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
        }
    }
    
    func loadTaskList() -> [[String:String]]? {
        let groupDefaults = NSUserDefaults.init(suiteName: "group.com.nevercry.videosaver")!
        
        if let jsonData:NSData = groupDefaults.objectForKey("downloadTaskList") as? NSData {
            do {
                guard let jsonArray:NSArray = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? NSArray else { return nil}
                return jsonArray as? [[String : String]]
            } catch {
                print("获取UserDefault出错")
            }
        }
        
        return nil
    }
    
    func saveTask(task:[String:String]) {
        let groupDefaults = NSUserDefaults.init(suiteName: "group.com.nevercry.videosaver")!
        
        var taskList = loadTaskList()
        
        if taskList != nil {
            taskList!.append(task)
        } else {
            taskList = [task]
        }
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(taskList!, options: .PrettyPrinted)
            groupDefaults.setObject(jsonData, forKey: "downloadTaskList")
            groupDefaults.synchronize()
        } catch {
            print("保存UserDefault出错")
        }
    }

    // MARK: - 保存视频
    @IBAction func downloadVideo(sender: AnyObject) {
        // 找不到shareUrl 提示用户无法使用插件
        // 禁止用户下载
        guard (self.videoURL != nil) else {
            self.downloadButton.enabled = false
            let alC = UIAlertController.init(title: "无法获取视频地址", message: "请先点击播放才能在浏览器中获得视频网址", preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
                self.hideExtensionWithCompletionHandler({ (Bool) -> Void in
                    self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
                })
                
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
            return
        }
        
        // 解析一下是否是优酷的m3u8 文件
        if (videoType == "m3u8") {
            // dataTask;
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.timeoutIntervalForRequest = 10
            let session = NSURLSession(configuration: config)
            session.dataTaskWithRequest(NSURLRequest(URL: videoURL!), completionHandler: { (data, res, error) in
                if ((data) != nil) {
                    let dataInfo = String(data: data!, encoding: NSUTF8StringEncoding)
                    print("dataInfo is \(dataInfo)")
                    let scaner = NSScanner(string: dataInfo!)
                    scaner.scanUpToString("http", intoString: nil)
                    var video_url:NSString?
                    scaner.scanUpToString(".ts", intoString: &video_url)
                    print("videoURL is \(video_url)")
                    if let _ = video_url {
                        self.videoURL = NSURL(string: (video_url as? String)!)
                        self.startDonload()
                        return
                    }
                }
                
                let alC = UIAlertController.init(title: "无法下载", message: "地址解析失败", preferredStyle: .Alert)
                let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: nil)
                alC.addAction(cancelAction)
                self.presentViewController(alC, animated: true, completion: nil)
            }).resume()
        } else {
            startDonload()
        }
    }
    
    func startDonload() {
        isDownLoading = true
        // 初始化一个Session
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = 10
        let urlSession = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        // 首先下载视频文件到cache 里
        print("start download url \(videoURL!)")
        urlSession.downloadTaskWithURL(videoURL!).resume()
    }
    
    func video(videoPath: String?, didFinishSavingWithError error: NSError?, contextInfo info: UnsafeMutablePointer<Void>) {
        // your completion code handled here
        if (error == nil) {
            hideExtensionWithCompletionHandler { (Bool) -> Void in
                self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
            }
        } else {
            // 提示用户保存失败
            let alC = UIAlertController.init(title: "保存失败", message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
        }
    }
    
    // MARK: - 取消下载
    @IBAction func cancel(sender: UIBarButtonItem) {
        hideExtensionWithCompletionHandler { (Bool) -> Void in
            self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
        }
    }
    
    
    // MARK: - 设置网络请求状态
    func setupNetWorkingStats() {
        dispatch_async(dispatch_get_main_queue()) { 
            self.progressView.hidden = !self.isDownLoading
            //self.pinView.hidden = !isDownLoading
            if (self.isDownLoading) {
                self.pinView.startAnimating()
            } else {
                self.pinView.stopAnimating()
            }
            
            self.progressLabel.hidden = !self.isDownLoading
            self.downloadButton.enabled = !self.isDownLoading
        }
    }
    
    // MARK: - NSURLSessionDelegate
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        isDownLoading = false
        print("Session invalid")
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        isDownLoading = false
        if ((error) != nil) {
            print("error happened: \(error!)")
            
            // 提示用户删除失败
            let alC = UIAlertController.init(title: "文件下载出错", message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
            
        }
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let fl_totalWr = Float(totalBytesWritten)
        let fl_totalExpected = Float(totalBytesExpectedToWrite)
        
        let progressValue = fl_totalWr/fl_totalExpected
        let totalSize = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: .Binary)

        dispatch_async(dispatch_get_main_queue(), {
            self.progressLabel.text = String(format: "%.1f%% of %@",  progressValue * 100, totalSize)
            self.progressView.progress = progressValue
        })
        
        print("progress is \(progressValue * 100) %")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        isDownLoading = false
        
        // MARK: 下载视频
        let fileManager = NSFileManager.defaultManager()
        let directory: NSURL = fileManager.containerURLForSecurityApplicationGroupIdentifier("group.com.nevercry.videosaver")!
        let videosDir = directory.URLByAppendingPathComponent("Videos", isDirectory: true)
        
        if !fileManager.fileExistsAtPath(videosDir.path!) {
            do {
                try fileManager.createDirectoryAtURL(videosDir, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("创建文件夹失败")
                // 提示用户删除失败
                let alC = UIAlertController.init(title: "创建文件夹失败", message: nil, preferredStyle: .Alert)
                let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
                })
                alC.addAction(cancelAction)
                self.presentViewController(alC, animated: true, completion: nil)
            }
        }
        
        
        
        let fileName = self.fileNameFromURL(self.videoURL!)
        let tmpVideoUrl = videosDir.URLByAppendingPathComponent("\(fileName)", isDirectory: false)

        if NSFileManager.defaultManager().fileExistsAtPath(tmpVideoUrl.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(tmpVideoUrl)
            } catch {
                // 提示用户删除失败
                let alC = UIAlertController.init(title: "文件读取失败", message: nil, preferredStyle: .Alert)
                let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
                })
                alC.addAction(cancelAction)
                self.presentViewController(alC, animated: true, completion: nil)
            }
        }
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(location, toURL: tmpVideoUrl)
        } catch {
            // 提示用户删除失败
            let alC = UIAlertController.init(title: "文件保存失败", message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
        }
        

        let bool = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum((tmpVideoUrl.path)!)
        if (bool) {
            UISaveVideoAtPathToSavedPhotosAlbum(tmpVideoUrl.path!, self, #selector(ShareViewController.video(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            // 提示用户无法保存
            let alC = UIAlertController.init(title: "保存失败", message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
        }
    }
    
    // MARK: - 动画过渡
    func hideExtensionWithCompletionHandler(completion:(Bool) -> Void) {
        UIView.animateWithDuration(0.20, animations: { () -> Void in
            self.navigationController!.view.transform = CGAffineTransformMakeTranslation(0, self.navigationController!.view.frame.size.height)
            },completion: completion)
    }
    
    
    // MARK: - 获取文件名
    func fileNameFromURL(videoURL: NSURL) -> String {
        var fileName = videoURL.lastPathComponent!
        
        if fileName.hasPrefix("videoplayback") {
            let urlComponents = self.pageUrl!.componentsSeparatedByString("=")
            let videoId = urlComponents.last
            fileName = videoId!
        }
        
        if !fileName.hasSuffix(".mp4") {
            fileName = fileName.stringByAppendingString(".mp4")
        }
        
        return fileName
    }

}
