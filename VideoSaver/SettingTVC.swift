//
//  SettingTVC.swift
//  VideoSaver
//
//  Created by nevercry on 16/6/26.
//  Copyright © 2016年 nevercry. All rights reserved.
//

import UIKit

class SettingTVC: UITableViewController {
    
    @IBOutlet weak var isSaveToPhotoAblumSwitch: UISwitch!

    @IBAction func switchToggle(sender: UISwitch) {
        
        let userDefault = NSUserDefaults(suiteName: "group.com.nevercry.videosaver")!
        userDefault.setObject(NSNumber(bool: sender.on), forKey: "isSaveToPhoteAblum")
        
        if userDefault.synchronize() {
            let isSaveToPhotoAblum =  userDefault.objectForKey("isSaveToPhoteAblum")! as! NSNumber
            print("now the photosave is \(isSaveToPhotoAblum.boolValue)")
        } else {
            print("user default sync error")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(done))
        
        // 检查是否需要保存到相册
        let userDefault = NSUserDefaults(suiteName: "group.com.nevercry.videosaver")!
        
        if userDefault.objectForKey("isSaveToPhoteAblum") == nil {
            print("no savetophote key")
            userDefault.setObject(NSNumber(bool: true), forKey: "isSaveToPhoteAblum")
            if userDefault.synchronize() {
                print("savetophoto change to true")
            } else {
                print("user default sync error")
            }
        }
        
        let isSaveToPhotoAblum =  userDefault.objectForKey("isSaveToPhoteAblum")! as! NSNumber
        print("isSaveToPhotoAblum is \(isSaveToPhotoAblum.boolValue)")
        
        isSaveToPhotoAblumSwitch.setOn(isSaveToPhotoAblum.boolValue, animated: false)
    }
    
    func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
