//
//  VideosTVC.swift
//  VideoSaver
//
//  Created by nevercry on 5/24/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideosTVC: UITableViewController {
    
    // MARK: - 数据源
    var videos: [Video] = []
    let fileManager = NSFileManager.defaultManager()
    let avPlayer = AVPlayerViewController()
    var isInPiP = false
    
    // 活动指示器
    var pinView: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        //注册视频播放器播放完成同志
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(rePlay), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        self.clearsSelectionOnViewWillAppear = true
        
        refreshControl?.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        
        // 设置画中画代理
        avPlayer.delegate = self
        avPlayer.allowsPictureInPicturePlayback = true
        
        // 通过FileManager 获取文件夹内的视频信息
        loadVideosInfo()
        
       
    }
    
    func testNew()  {
        print("test New!!!")
    }
    
    func updateForPiP()  {
        print("new ass!")
        if let _ = presentedViewController {
            if isInPiP {
                dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
        
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func rePlay() {
        avPlayer.player?.seekToTime(kCMTimeZero)
        avPlayer.player?.play()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 下拉刷新
    func refresh() {
        videos = []
        loadVideosInfo()
        tableView.reloadData()
        if let _ = refreshControl?.refreshing {
            refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - 清空缓存
    @IBAction func clearCache(sender: AnyObject) {
        let alVC = UIAlertController.init(title: "是否清空缓存？", message: nil, preferredStyle: .ActionSheet)
        alVC.modalPresentationStyle = .Popover
        
        let cancelAction = UIAlertAction.init(title: "取消", style: .Cancel, handler: nil)
        let clearAction = UIAlertAction.init(title: "清空", style: .Destructive) { (action) in
            let groupDir = self.fileManager.containerURLForSecurityApplicationGroupIdentifier(Constant.GroupID)!
            let videosDir = groupDir.URLByAppendingPathComponent("Videos", isDirectory: true)
            if self.fileManager.fileExistsAtPath(videosDir.path!) {
                do {
                    try self.fileManager.removeItemAtURL(videosDir)
                    self.videos = []
                    self.loadVideosInfo()
                    self.tableView.reloadData()
                } catch {
                    print("error happened need hanlde")
                }
            }
        }
        alVC.addAction(cancelAction)
        alVC.addAction(clearAction)
        
        if let presenter = alVC.popoverPresentationController {
            presenter.barButtonItem = sender as? UIBarButtonItem
        }        
        presentViewController(alVC, animated: true, completion: nil)
    }
    
    // MARK: - 获取缓存文件中的视频信息
    func loadVideosInfo() {
        let groupDirURL = fileManager.containerURLForSecurityApplicationGroupIdentifier(Constant.GroupID)!
        print("group url is \(groupDirURL)")
        let videosDir = groupDirURL.URLByAppendingPathComponent("Videos", isDirectory: true)
        // 检查文件夹是否存在
        if fileManager.fileExistsAtPath(videosDir.path!) {
            
            let resourceKeys = [NSURLLocalizedNameKey, NSURLAddedToDirectoryDateKey, NSURLFileSizeKey]
            let directoryEnumerator = fileManager.enumeratorAtURL(videosDir, includingPropertiesForKeys: resourceKeys, options: [.SkipsHiddenFiles], errorHandler: nil)!
            
            for case let fileURL as NSURL in directoryEnumerator {
                guard let resourceValues = try? fileURL.resourceValuesForKeys(resourceKeys),
                    let date = resourceValues[NSURLAddedToDirectoryDateKey] as? NSDate,
                    let name = resourceValues[NSURLLocalizedNameKey] as? String,
                    let size = resourceValues[NSURLFileSizeKey] as? NSNumber
                    else {
                        continue
                }
                
                
                let video = Video(title: name, createdDate: date, fileSize: size, path: fileURL.path!, thumbnail: nil)
                videos.append(video)
            }
        }
    }
    
    // MARK: - 播放视频
    func playVideo(player: AVPlayer) {
        player.actionAtItemEnd = .None
        avPlayer.modalTransitionStyle = .CrossDissolve
        avPlayer.player = player
        
        presentViewController(avPlayer, animated: true) {
            self.avPlayer.player?.play()
            self.updateForPiP()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constant.VideoCellIdentifier, forIndexPath: indexPath)

        // Configure the cell...
        var video = videos[indexPath.row]
        cell.textLabel?.text = video.title
        
        let fileSizeText = NSByteCountFormatter.stringFromByteCount(Int64(video.fileSize.intValue), countStyle: .Binary)
        let addDateText = NSDateFormatter.localizedStringFromDate(video.createdDate, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
        let duration = video.duration()
        cell.detailTextLabel?.text = "\(fileSizeText)    \(NSLocalizedString("时长", comment: "时长")): \(duration)    \(NSLocalizedString("日期", comment: "日期")): \(addDateText)"
        cell.imageView?.backgroundColor = UIColor.blackColor()
        cell.imageView?.image = nil
        
        if let thumbnail = video.thumbnail {
            cell.imageView?.image = thumbnail
        } else {
            let imageDownloadQeue = dispatch_queue_create("imageDownload", nil)
            let videoUrl = NSURL(fileURLWithPath: video.path)
            dispatch_async(imageDownloadQeue) {
                let image = self.getPreviewImageForVideoAtURL(videoUrl, atInterval: 2)
                if let _ = image {
                    dispatch_async(dispatch_get_main_queue(), {
                        let newVideo = self.videos[indexPath.row]
                        if video.path == newVideo.path {
                            cell.imageView?.image = image
                            video.thumbnail = image
                            self.videos[indexPath.row] = video
                            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                        }
                    })
                }
            }
        }
        
        return cell
    }
    

    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction.init(style: UITableViewRowActionStyle.Destructive, title: NSLocalizedString("Delete", comment: "删除")) { (action, indexPath) in
            let video = self.videos[indexPath.row]
            if self.fileManager.fileExistsAtPath(video.path) {
                do {
                    try self.fileManager.removeItemAtPath(video.path)
                    self.videos.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                } catch {
                    let alVC = UIAlertController(title: NSLocalizedString("删除失败", comment: "删除失败"), message: nil, preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: nil)
                    alVC.addAction(cancelAction)
                    self.presentViewController(alVC, animated: true, completion: {
                        self.tableView.endEditing(true)
                    })
                }
            }
        }
        
        let saveToAblumAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("保存", comment: "保存")) { (action, indexPath) in
            let video = self.videos[indexPath.row]
            
            let bool = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum((video.path))
            if (bool) {
                self.pinView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
                self.pinView?.center = self.view.center
                self.pinView?.hidesWhenStopped = true
                self.pinView?.startAnimating()
                self.navigationController?.view.addSubview(self.pinView!)
                UISaveVideoAtPathToSavedPhotosAlbum(video.path, self, #selector(VideosTVC.video(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                // 提示用户无法保存
                let alerTitle = NSLocalizedString("保存失败", comment: "保存失败")
                let cancelAction = UIAlertAction.init(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: { (action) in
                })
                self.showAlert(alerTitle, message: nil, actions: [cancelAction])
            }
        }
        
        saveToAblumAction.backgroundColor = UIColor.grayColor()
        
        
        return [deleteAction,saveToAblumAction]
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let video = videos[indexPath.row]
        let url = NSURL(fileURLWithPath: video.path)
        let player = AVPlayer(URL: url)
        playVideo(player)
    }

    // MARK: - 获取视频缩略图
    func getPreviewImageForVideoAtURL(videoURL: NSURL, atInterval: Int) -> UIImage? {
        print("Taking pic at \(atInterval) second")
        let asset = AVAsset(URL: videoURL)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        //If possible - take not the first frame (it could be completely black or white on camara's videos)
        let tmpTime = CMTimeMakeWithSeconds(Float64(atInterval), 100)
        time.value = min(time.value, tmpTime.value)
        
        do {
            let img = try assetImgGenerate.copyCGImageAtTime(time, actualTime: nil)
            let frameImg = UIImage(CGImage: img)
            let compressImage = frameImg.clipAndCompress(64.0/44.0, compressionQuality: 0.5)
            let newImageSize = CGSizeMake(64, 44)
            UIGraphicsBeginImageContextWithOptions(newImageSize, false, 0.0)
            compressImage.drawInRect(CGRectMake(0, 0, newImageSize.width, newImageSize.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        } catch {
            /* error handling here */
            print("获取视频截图失败")
        }
        return nil
    }
}

extension VideosTVC: AVPlayerViewControllerDelegate {
    
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(playerViewController: AVPlayerViewController) -> Bool {
        print("playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart")
        return true
    }
    
    func playerViewController(playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: (Bool) -> Void) {
        print("restoreUserInterfaceForPictureInPictureStopWithCompletionHandler")
        if let _ = self.presentedViewController {
            
        } else {
            presentViewController(playerViewController, animated: true, completion: nil)
        }
        
        completionHandler(true)
    }
    
    func playerViewControllerWillStartPictureInPicture(playerViewController: AVPlayerViewController) {
        print("WillStartPictureInPicture(")
    }
    
    func playerViewControllerDidStartPictureInPicture(playerViewController: AVPlayerViewController) {
        print("DidStartPictureInPicture")
        isInPiP = true
    }
    
    func playerViewControllerWillStopPictureInPicture(playerViewController: AVPlayerViewController) {
        print("WillStopPictureInP")
        isInPiP = false
    }
    
    func playerViewControllerDidStopPictureInPicture(playerViewController: AVPlayerViewController) {
        print("DidStopPictureInP")
    }
}

extension VideosTVC {
    func video(videoPath: String?, didFinishSavingWithError error: NSError?, contextInfo info: UnsafeMutablePointer<Void>) {
        // your completion code handled here
        self.pinView?.stopAnimating()
        self.pinView?.removeFromSuperview()
        self.pinView = nil
        var alTitle = NSLocalizedString("保存成功", comment: "保存成功")
        if (error != nil) {
            // 提示用户保存失败
            alTitle = NSLocalizedString("保存失败", comment: "保存失败")
        }
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("确认", comment: "确认"), style: .Cancel, handler: { (action) in
        })
        
        showAlert(alTitle, message: nil, actions: [cancelAction])
    }
}