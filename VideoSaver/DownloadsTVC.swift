//
//  DownloadsTVC.swift
//  VideoSaver
//
//  Created by nevercry on 5/28/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit

class DownloadsTVC: UITableViewController {
    
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("group.com.nevercry.videosaver")
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    var downloadTasks:[Download] = []
    
    var activeDownloads = [String: Download]()
    
    // MARK: Download methods
    
    // Called when the Download button for a task is tapped
    func startDownload(task: Download) {
        if let url = NSURL(string: task.url) {
            task.downloadTask = downloadsSession.downloadTaskWithURL(url)
            task.downloadTask!.resume()
            task.isDownloading = true
            
            activeDownloads[task.url] = task
        }
    }
    
    // Called when the Pause button for a task is tapped
    func pauseDownload(task: Download) {
        if task.isDownloading {
            task.downloadTask?.cancelByProducingResumeData({ (data) in
                if data != nil {
                    task.resumeData = data
                }
            })
            task.isDownloading = false
        }
    }
    
    // Called when the Cancel button for a task is tapped
    func cancelDownload(task: Download) {
        task.downloadTask?.cancel()
        activeDownloads[task.url] = nil
    }
    
    // Called when the Resume button for a task is tapped
    func resumeDownload(task: Download) {
        if let resumeData = task.resumeData {
            task.downloadTask = downloadsSession.downloadTaskWithResumeData(resumeData)
            task.downloadTask?.resume()
            task.isDownloading = true
        } else if let url = NSURL(string: task.url) {
            task.downloadTask = downloadsSession.downloadTaskWithURL(url)
            task.downloadTask?.resume()
            task.isDownloading = true
        }
    }
    
    func taskIndex(downloadTask: NSURLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            for (index, task) in downloadTasks.enumerate() {
                if url == task.url {
                    return index
                }
            }
        }
        return nil
    }
    
    // MARK: - 获取下载列表
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
    
    func saveTaskList() {
        let groupDefaults = NSUserDefaults.init(suiteName: "group.com.nevercry.videosaver")!
        var arr = Array<[String:String]>()
        for item in downloadTasks {
            let dic = ["fileName":item.fileName,"url":item.url]
            arr.append(dic)
        }
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(arr, options: .PrettyPrinted)
            groupDefaults.setObject(jsonData, forKey: "downloadTaskList")
            groupDefaults.synchronize()
        } catch {
            print("保存UserDefault出错")
        }
    }
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        _ = self.downloadsSession
        
        if let taskList = loadTaskList() {
            for item in taskList {
                let download = Download(url: item["url"]!,fileName: item["fileName"]!)
                downloadTasks.append(download)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        downloadsSession.invalidateAndCancel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadTasks.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("VideoCell", forIndexPath: indexPath) as! VideoCell
        cell.delegate = self
        
        let task = downloadTasks[indexPath.row]
        let videoName = task.fileName

        cell.titleLabel.text = videoName
        
        let title = (task.isDownloading) ? "Pause" : "Resume"
        cell.pauseButton.setTitle(title, forState: UIControlState.Normal)
        
        var showDownloadControls = false
        if let download = activeDownloads[task.url] {
            showDownloadControls = true
            
            cell.progressView.progress = download.progress
            cell.progressLabel.text = (download.isDownloading) ? "Downloading..." : "Paused"
        }
        
        cell.downloadButton.hidden = showDownloadControls
        
        cell.progressView.hidden = !showDownloadControls
        cell.progressLabel.hidden = !showDownloadControls
        
        cell.pauseButton.hidden = !showDownloadControls
        cell.cancelButton.hidden = !showDownloadControls
        
        // Configure the cell...

        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 62.0
    }
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let download = downloadTasks[indexPath.row]
        return (activeDownloads[download.url] != nil) ? false : true
    }
    

    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            downloadTasks.removeAtIndex(indexPath.row)
            saveTaskList()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
}

// MARK: - NSURLSessionDownloadDelegate
extension DownloadsTVC: NSURLSessionDownloadDelegate {
    func video(videoPath: String?, didFinishSavingWithError error: NSError?, contextInfo info: UnsafeMutablePointer<Void>) {
        // your completion code handled here
        if (error != nil) {
            // 提示用户保存失败
            let alC = UIAlertController.init(title: "保存失败", message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
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
        
        let taskList = loadTaskList()!
        var fileName = ""
        for elem in taskList {
            if elem["url"] ==  downloadTask.originalRequest!.URL!.absoluteString {
                fileName = elem["fileName"]!
                break
            }
        }
        
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
            UISaveVideoAtPathToSavedPhotosAlbum(tmpVideoUrl.path!, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            // 提示用户无法保存
            let alC = UIAlertController.init(title: "保存失败", message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction.init(title: "确认", style: .Cancel, handler: { (action) in
            })
            alC.addAction(cancelAction)
            self.presentViewController(alC, animated: true, completion: nil)
        }
        
        

        if let index = taskIndex(downloadTask) {
            dispatch_async(dispatch_get_main_queue(), {
                self.downloadTasks.removeAtIndex(index)
                self.saveTaskList()
                let url = downloadTask.originalRequest!.URL!.absoluteString
                self.activeDownloads[url] = nil
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
            })
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if let index = taskIndex(downloadTask) {
            let download = downloadTasks[index]
            download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
            let totalSize = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: .Binary)
            if let videoCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? VideoCell {
                dispatch_async(dispatch_get_main_queue(), {
                    videoCell.progressView.progress = download.progress
                    videoCell.progressLabel.text =  String(format: "%.1f%% of %@",  download.progress * 100, totalSize)
                })
            }
        }
    }
}

// MARK: - NSURLSessionDelegate
extension DownloadsTVC: NSURLSessionDelegate {
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                dispatch_async(dispatch_get_main_queue(), {
                    completionHandler()
                })
            }
        }
    }
}

// MARK: - VideoCellDelegate
extension DownloadsTVC: VideoCellDelegate {
    func pauseTapped(cell: VideoCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let task = downloadTasks[indexPath.row]
            pauseDownload(task)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func resumeTapped(cell: VideoCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let task = downloadTasks[indexPath.row]
            resumeDownload(task)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func cancelTapped(cell: VideoCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let task = downloadTasks[indexPath.row]
            cancelDownload(task)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func downloadTapped(cell: VideoCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let task = downloadTasks[indexPath.row]
            startDownload(task)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
}
