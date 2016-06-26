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
    
    // MARK: Constents
    struct Constents {
        static let VideoCellIdentifier = "Video Cell"
    }
    
    // MARK: - 数据源
    var videos: [Video] = []
    let fileManager = NSFileManager.defaultManager()
    let avPlayer = AVPlayerViewController()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        refreshControl?.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        
        // 设置画中画代理
        avPlayer.delegate = self
        avPlayer.allowsPictureInPicturePlayback = true
        
        // 通过FileManager 获取文件夹内的视频信息
        loadVideosInfo()
        
        //注册视频播放器播放完成同志
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(rePlay), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
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
        let cancelAction = UIAlertAction.init(title: "取消", style: .Cancel, handler: nil)
        let clearAction = UIAlertAction.init(title: "清空", style: .Destructive) { (action) in
            let groupDir = self.fileManager.containerURLForSecurityApplicationGroupIdentifier("group.com.nevercry.videosaver")!
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
        presentViewController(alVC, animated: true, completion: nil)
    }
    
    // MARK: - 获取缓存文件中的视频信息
    func loadVideosInfo() {
        let groupDirURL = fileManager.containerURLForSecurityApplicationGroupIdentifier("group.com.nevercry.videosaver")!
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
        let cell = tableView.dequeueReusableCellWithIdentifier(Constents.VideoCellIdentifier, forIndexPath: indexPath)

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
    

    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let video = videos[indexPath.row]
            if fileManager.fileExistsAtPath(video.path) {
                do {
                    try fileManager.removeItemAtPath(video.path)
                    videos.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                } catch {
                    let alVC = UIAlertController(title: "删除失败", message: nil, preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "确认", style: .Cancel, handler: nil)
                    alVC.addAction(cancelAction)
                    presentViewController(alVC, animated: true, completion: { 
                        self.tableView.endEditing(true)
                    })
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
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
    
}






