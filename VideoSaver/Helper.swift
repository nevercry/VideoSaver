//
//  Helper.swift
//  VideoSaver
//
//  Created by nevercry on 5/27/16.
//  Copyright © 2016 nevercry. All rights reserved.
//

import UIKit


extension UIImage {
    // MARK: - 根据宽高比截取图片中心并压缩
    
    /**
     根据宽高比截取图片中心
     
     - parameter ratio:              截取的宽高比
     - parameter compressionQuality: 压缩比 取值范围 0.0 到 1.0 之间
     
     - returns: 截取压缩之后的图片
     */
    func clipAndCompress(ratio: CGFloat, compressionQuality: CGFloat) -> UIImage {
        
        let height = self.size.height
        let width = self.size.width
        
        var clipImageWidth, clipImageHeight:CGFloat
        var imageDrawOrgin_X, imageDrawOrgin_Y:CGFloat
        
        if (width/height < 1) {
            clipImageWidth = width
            clipImageHeight = clipImageWidth/ratio
            
            imageDrawOrgin_X = 0
            imageDrawOrgin_Y = -(height-clipImageHeight)/2
        } else if (width/height > 1) {
            clipImageHeight = height
            clipImageWidth = clipImageHeight*ratio
            
            imageDrawOrgin_X = -(width - clipImageWidth)/2
            imageDrawOrgin_Y = 0
        } else {
            clipImageWidth = width
            clipImageHeight = clipImageWidth/ratio
            
            imageDrawOrgin_X = 0
            imageDrawOrgin_Y = 0
        }
        
        let clipImageSize = CGSizeMake(clipImageWidth, clipImageHeight)
        UIGraphicsBeginImageContextWithOptions(clipImageSize, false, 0.0)
        
        self.drawAtPoint(CGPointMake(imageDrawOrgin_X, imageDrawOrgin_Y))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        
        
        let comressImage = UIImage(data: UIImageJPEGRepresentation(newImage, compressionQuality)!)
        return comressImage!
    }
    

}