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
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var saveLinkButton: UIBarButtonItem!
    
    // 计算剩余下载时间
    var _lastDownloadDate: NSDate?
    let SMOOTHING_FACTOR = 0.005
    var _averageSpeed: Double?
    var _progress: NSProgress?
    var _myContext: Void?
    
    var videoInfo: [String: String] = [:]  // Keys: "url","type","poster","duration","title"，“source”
    var userAction: ShareActions = .Save
    
    enum ShareActions: Int {
        case Save,Download
    }
    
    var isDownLoading = false {
        didSet {
            setupNetWorkingStats()
        }
    }
    
    func updateUI() {
        isDownLoading = false
        if let _ = videoInfo["url"] {
            saveLinkButton.enabled = true
            downloadButton.enabled = true
        } else {
            saveLinkButton.enabled = false
            downloadButton.enabled = false
        }
    }
    
    // MARK: 显示没有URL的警告
    func showNoURLAlert() {
        let alertTitle = NSLocalizedString("Can't fetch video link", comment: "无法获取到视频地址")
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "确认"), style: .Cancel, handler: { (action) in
            self.hideExtensionWithCompletionHandler({ (Bool) -> Void in
                self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
            })
            
        })
        showAlert(alertTitle, message: nil, actions: [cancelAction])
    }
    
    // MARK: 显示警告
    func showAlert(title:String?, message: String?, actions: [UIAlertAction])  {
        let alC = UIAlertController.init(title: title, message: message, preferredStyle: .Alert)
        for (_,action) in actions.enumerate() {
            alC.addAction(action)
        }
        dispatch_async(dispatch_get_main_queue()) { 
             self.presentViewController(alC, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height)
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.transform = CGAffineTransformIdentity
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        pinView.stopAnimating()
        
        let propertyList = String(kUTTypePropertyList)
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
            itemProvider = item.attachments?.first as? NSItemProvider where itemProvider.hasItemConformingToTypeIdentifier(propertyList)
            else { return }
        
        itemProvider.loadItemForTypeIdentifier(propertyList, options: nil, completionHandler: { (diction, error) in
            guard let shareDic = diction as? NSDictionary,
                results = shareDic.objectForKey(NSExtensionJavaScriptPreprocessingResultsKey) as? NSDictionary,
                vInfo = results.objectForKey("videoInfo") as? NSDictionary else { return }
            
            // 视频信息
            self.videoInfo["title"] = vInfo["title"] as? String
            self.videoInfo["duration"] = vInfo["duration"] as? String
            self.videoInfo["poster"] = vInfo["poster"] as? String
            self.videoInfo["url"] = vInfo["url"] as? String
            self.videoInfo["type"] = vInfo["type"] as? String
            self.videoInfo["source"] = vInfo["source"] as? String
            
            print("videoInfo is \(self.videoInfo)")
            
            guard let videoURLStr = self.videoInfo["url"] where videoURLStr.characters.count > 0 else { return }
            // 视频地址
            print("video url is \(videoURLStr)")
            // 设置文件名
            dispatch_async(dispatch_get_main_queue(), {
                self.title = self.videoInfo["title"]
                self.linkLabel.text = "\(NSLocalizedString("Link", comment: "链接")): \(videoURLStr)"
                self.updateUI()
            })
        })
       
        print("分享内容是: \(item.attributedContentText?.string)")
    }

    // MARK: - 添加到下载列表
    @IBAction func saveToDownLoadList(sender: UIBarButtonItem) {
        userAction = ShareActions.Save
        // 找不到shareUrl 提示用户无法使用插件
        guard (videoInfo["url"] != nil) else {
            saveLinkButton.enabled = false
            showNoURLAlert()
            return
        }
        
        // 解析一下是否是优酷的m3u8 文件
        if (videoInfo["type"] == "m3u8") {
            parse_m3u8(userAction)
        } else if (videoInfo["type"] == "xml") {
            // 是否为twimg的xml文件
            parseXML()
        } else {
            startSave()
        }
    }
    
    // MARK: - 解析m3u8
    func parse_m3u8(action: ShareActions)  {
        isDownLoading = true
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = 10
        let session = NSURLSession(configuration: config)
        
        let videoURL = NSURL(string: videoInfo["url"]!)
        session.dataTaskWithRequest(NSURLRequest(URL: videoURL!), completionHandler: { (data, res, error) in
           self.isDownLoading = false
            
            guard (data != nil) else {
                let alertTitle = NSLocalizedString("Operation Failed", comment: "操作失败")
                let message = NSLocalizedString("Try again", comment: "请重试")
                let cancelAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "确认"), style: .Cancel, handler: {
                    action in
                    self.hideExtensionWithCompletionHandler({ (Bool) -> Void in
                        self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
                    })
                })
                self.showAlert(alertTitle, message: message, actions: [cancelAction])
                return
            }
            
            let dataInfo = String(data: data!, encoding: NSUTF8StringEncoding)
            let scaner = NSScanner(string: dataInfo!)
            scaner.scanUpToString("http", intoString: nil)
            var firstUrl:NSString?
            scaner.scanUpToString(".ts", intoString: &firstUrl)
            // 备用地址
            scaner.scanUpToString("keyframe=1", intoString: nil)
            // 移到关键帧
            scaner.scanUpToString("http", intoString: nil)
            var video_url:NSString?
            scaner.scanUpToString(".ts", intoString: &video_url)
            print("videoURL is \(video_url)")
            
            if video_url == nil {
                video_url = firstUrl
            }
            
            guard (video_url != nil) && video_url!.hasSuffix("mp4") else {
                let cancelAction = UIAlertAction(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: nil)
                self.showAlert(NSLocalizedString("地址解析失败", comment: "地址解析失败"), message: nil, actions: [cancelAction])
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.videoInfo["url"] = video_url! as String
                self.linkLabel.text = "\(NSLocalizedString("Link", comment: "链接")): \(video_url!)";
                switch action {
                case .Download:
                    self.startDonload()
                    break
                case .Save:
                    self.startSave()
                }
            })
        }).resume()
    }
    
    // MARK: - 解析xml
    func parseXML()  {
        isDownLoading = true
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = 10
        let session = NSURLSession(configuration: config)
        let videoURL = NSURL(string: videoInfo["url"]!)
        session.dataTaskWithRequest(NSURLRequest(URL: videoURL!), completionHandler: { (data, res, error) in
            self.isDownLoading = false
            guard (data != nil) else {
                let alertTitle = NSLocalizedString("Operation Failed", comment: "操作失败")
                let message = NSLocalizedString("Try again", comment: "请重试")
                let cancelAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "确认"), style: .Cancel, handler: {
                    action in
                    self.hideExtensionWithCompletionHandler({ (Bool) -> Void in
                        self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
                    })
                })
                self.showAlert(alertTitle, message: message, actions: [cancelAction])
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                let xmlParser = NSXMLParser(data: data!)
                xmlParser.delegate = self
                if !xmlParser.parse() {
                    let cancelAction = UIAlertAction(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: nil)
                    self.showAlert(NSLocalizedString("地址解析失败", comment: "地址解析失败"), message: nil, actions: [cancelAction])
                }
            })
        }).resume()
    }
    
    
    
    func startSave() {
        saveMark(videoInfo)
    }
    
    func loadMarkList() -> [[String:String]]? {
        let groupDefaults = NSUserDefaults.init(suiteName: "group.nevercry.videoMarks")!
        
        if let jsonData:NSData = groupDefaults.objectForKey("savedMarks") as? NSData {
            do {
                guard let jsonArray:NSArray = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? NSArray else { return nil}
                return jsonArray as? [[String : String]]
            } catch {
                print("获取UserDefault出错")
            }
        }
        
        return nil
    }
    
    func saveMark(mark:[String:String]) {
        let groupDefaults = NSUserDefaults.init(suiteName: "group.nevercry.videoMarks")!
        
        var markList = loadMarkList()
        
        if markList != nil {
            markList!.append(mark)
        } else {
            markList = [mark]
        }
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(markList!, options: .PrettyPrinted)
            groupDefaults.setObject(jsonData, forKey: "savedMarks")
            groupDefaults.synchronize()
        } catch {
            print("保存UserDefault出错")
            let cancelAction = UIAlertAction(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: nil)
            showAlert(NSLocalizedString("保存出错", comment: "保存出错"), message: nil, actions: [cancelAction])
            return
        }
        
        hideExtensionWithCompletionHandler { (Bool) -> Void in
            self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
        }
    }
    
    // MARK: - 直接下载视频
    @IBAction func downloadVideo(sender: AnyObject) {
        userAction = ShareActions.Download
        guard (videoInfo["url"] != nil) else {
            self.downloadButton.enabled = false
            showNoURLAlert()
            return
        }
        
        // 解析一下是否是优酷的m3u8 文件
        if (videoInfo["type"] == "m3u8") {
            parse_m3u8(userAction)
        } else {
            startDonload()
        }
    }
    
    func startDonload() {
        if let videoURL = NSURL(string: videoInfo["url"]!) {
            isDownLoading = true
            // 初始化一个Session
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.timeoutIntervalForRequest = 10
            let urlSession = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
            
            // 首先下载视频文件到cache 里
            print("start download url \(videoInfo["url"])")
            _lastDownloadDate = NSDate()
            urlSession.downloadTaskWithURL(videoURL).resume()
        } else {
            showNoURLAlert()
        }
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
            if (self.isDownLoading) {
                self.pinView.startAnimating()
            } else {
                self.pinView.stopAnimating()
            }
            
            self.progressLabel.hidden = !self.isDownLoading
            self.downloadButton.enabled = !self.isDownLoading
            self.saveLinkButton.enabled = !self.isDownLoading
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
            let alertTitle = "文件下载出错"
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
            })
            
            showAlert(alertTitle, message: nil, actions: [cancelAction])
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if (_progress == nil) {
            _progress = NSProgress(totalUnitCount: totalBytesExpectedToWrite)
            _progress?.kind = NSProgressKindFile
            progressView.observedProgress = _progress
        }
        
        
        dispatch_async(dispatch_get_main_queue(), {
            self.progressLabel.text = self._progress?.localizedAdditionalDescription
        })
        
        let senconds = abs(_lastDownloadDate!.timeIntervalSinceDate(NSDate()))
        _lastDownloadDate = NSDate()
        
        if (_averageSpeed == nil) {
            _averageSpeed = Double(bytesWritten) / senconds
        } else {
            _averageSpeed = SMOOTHING_FACTOR * (Double(bytesWritten) / senconds) + (1 - SMOOTHING_FACTOR) * _averageSpeed!
        }
        
        let remainingTime = NSTimeInterval((Double(totalBytesExpectedToWrite) - Double(totalBytesWritten)) / _averageSpeed!)
        
        
        _progress?.setUserInfoObject(remainingTime, forKey: "NSProgressEstimatedTimeRemainingKey")
        _progress?.completedUnitCount = totalBytesWritten
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        _progress = nil
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
                let alerTitle = NSLocalizedString("创建文件夹失败", comment: "创建文件夹失败")
                let cancelAction = UIAlertAction.init(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: { (action) in
                })
                showAlert(alerTitle, message: nil, actions: [cancelAction])
            }
        }
        
        
        let fileName = self.fileNameFromURL(location)
        let tmpVideoUrl = videosDir.URLByAppendingPathComponent("\(fileName)", isDirectory: false)

        if NSFileManager.defaultManager().fileExistsAtPath(tmpVideoUrl.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(tmpVideoUrl)
            } catch {
                // 提示用户删除失败
                let alerTitle = NSLocalizedString("文件读取失败", comment: "文件读取失败")
                let cancelAction = UIAlertAction.init(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: { (action) in
                })
                showAlert(alerTitle, message: nil, actions: [cancelAction])
            }
        }
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(location, toURL: tmpVideoUrl)
        } catch {
            // 提示用户删除失败
            let alertTitle = NSLocalizedString("文件保存失败", comment: "文件保存失败")
            let cancelAction = UIAlertAction.init(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: { (action) in
            })
            showAlert(alertTitle, message: nil, actions: [cancelAction])
        }
        
        let bool = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum((tmpVideoUrl.path)!)
        if (bool) {
            UISaveVideoAtPathToSavedPhotosAlbum(tmpVideoUrl.path!, self, #selector(ShareViewController.video(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            // 提示用户无法保存
            let alerTitle = NSLocalizedString("保存失败", comment: "保存失败")
            let cancelAction = UIAlertAction.init(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: { (action) in
            })
            showAlert(alerTitle, message: nil, actions: [cancelAction])
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
        
        print("location's lastPathComponent is \(fileName)")
        
        if fileName.hasPrefix("videoplayback") {
            let urlComponents = videoInfo["source"]!.componentsSeparatedByString("=")
            let videoId = urlComponents.last
            fileName = videoId!
        }
        
        if !fileName.hasSuffix(".mp4") {
            fileName = fileName.stringByAppendingString(".mp4")
        }
        
        return fileName
    }
}

// MARK:- NSXMLParserDelegate
extension ShareViewController: NSXMLParserDelegate {
    func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) {
        let videoURL = String(data: CDATABlock, encoding: NSUTF8StringEncoding)
        print("url is \(videoURL)")
        
        if let _ = videoURL {
            self.videoInfo["url"] = videoURL!
            dispatch_async(dispatch_get_main_queue(), { 
                self.linkLabel.text = "\(NSLocalizedString("Link", comment: "链接")): \(videoURL!)";
                if (self.userAction == ShareActions.Save) {
                    self.startSave()
                } else {
                    self.startDonload()
                }
            })
        }
    }
}

//// MARK: - KVO
//extension ShareViewController {
//    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//        if context == &_myContext {
//            
//            print("Description is \(_progress?.localizedAdditionalDescription)")
//        } else {
//            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
//        }
//    }
//}
