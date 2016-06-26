//
//  VideoCell.swift
//  VideoSaver
//
//  Created by nevercry on 5/28/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit

protocol VideoCellDelegate {
    func pauseTapped(cell: VideoCell)
    func resumeTapped(cell: VideoCell)
    func cancelTapped(cell: VideoCell)
    func downloadTapped(cell: VideoCell)
}

class VideoCell: UITableViewCell {
    
    var delegate: VideoCellDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var imageV: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    
    @IBAction func pauseOrResumeTapped(sender: AnyObject) {
        if(pauseButton.titleLabel!.text == "Pause") {
            delegate?.pauseTapped(self)
        } else {
            delegate?.resumeTapped(self)
        }
    }
    
    @IBAction func cancelTapped(sender: AnyObject) {
        delegate?.cancelTapped(self)
    }
    
    @IBAction func downloadTapped(sender: AnyObject) {
        delegate?.downloadTapped(self)
    }
}
