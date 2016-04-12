//
//  DownloadFIleViewController.swift
//  NSURLSessionDemo
//
//  Created by hah on 16/4/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

import UIKit

class DownloadFIleViewController: BaseViewController {
    
    var resumeData = NSData()
    
    @IBOutlet weak var progress: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var imageView: UIImageView!
    
    let URLString = "http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1308/15/c4/24495135_1376532082021.jpg"
    
    /*
    init sesion and download task
    */
    lazy var session:NSURLSession = {
        let config  = NSURLSessionConfiguration.defaultSessionConfiguration()
        let myQueue = NSOperationQueue()
        myQueue.maxConcurrentOperationCount = 1
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: myQueue)
        return session
    }()
    
    var downloadTask = NSURLSessionDownloadTask()
    
    var imgPath = NSURL()
    
    class func downloadFileViewController() -> DownloadFIleViewController {
        return NSBundle.mainBundle().loadNibNamed("DownloadFileView", owner: nil, options: nil).last as! DownloadFIleViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.progress = 0
        
        
    }
    
    func sendRequest(requestStr:String) {
        let manager = AHNetworkingManager.manager
        downloadTask = manager.get(URLString, finish: { (task, distinationURL) -> Void in
            
                self.imgPath = distinationURL
                
                assert(self.imgPath.absoluteString.characters.count>0, "imgPath is not exit")
                
                NSLog("download completed in path:\(self.imgPath)")
                let data = NSData(contentsOfURL: self.imgPath)
                let img = UIImage(data: data!)
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.imageView.image = img
                }
            
            }, failed: {(task,error) -> Void in
                
                NSLog("下载失败，reason:\(error?.localizedDescription)")
                
            },downloadProgress: { (task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) -> Void in
                
                let p = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.progress.text = "\(p)"
                    self.progressBar.progress = p
                }
                NSLog("progress:\(p)")
                
        })
    }
    
    @IBAction func startDownload(sender: AnyObject) {
        NSLog("task start")

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.imageView.image = UIImage(named: "placeholder")
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) { () -> Void in
            self.sendRequest(self.URLString)
        }
        
        
    }
}