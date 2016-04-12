//
//  AHNetworkingManager.swift
//  NSURLSessionDemo
//
//  Created by hah on 16/4/11.
//  Copyright © 2016年 nuclear. All rights reserved.
//

import UIKit

enum Method:String {
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

/** 请求成功的回调 */
typealias SucceedHandler = (NSData?, NSURLResponse?) -> Void
/** 请求失败的回调 */
typealias FailedHandler = (NSURLSessionTask?, NSError?) -> Void
/** 下载进度回调 */
typealias DownloadProgressBlock = (NSURLSessionDownloadTask, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void
/** 上传进度回调 */
typealias UploadProgressBlock = (NSURLSessionDownloadTask, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void
/** 完成下载回调 */
typealias FinishDownloadBlock = (NSURLSessionDownloadTask, distinationURL: NSURL) -> Void
/** 完成任务回调 */
typealias CompletionBlock = (NSURLSessionTask, responseObj:AnyObject?, error: NSError?) -> Void

class AHNetworkingManager: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate,NSURLSessionDownloadDelegate, NSURLSessionDataDelegate{
    
    var successHandler:SucceedHandler?
    var failHandler:FailedHandler?
    
    var downloadProgressHandler:DownloadProgressBlock?
    var uploadProgressHandler:UploadProgressBlock?
    
    var finishHandler:FinishDownloadBlock?
    var completionHandler:CompletionBlock?
    
    var responseObj:AnyObject?

    var session:NSURLSession?
    
    lazy var myQueue:NSOperationQueue = {
        let q = NSOperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
    internal static let manager:AHNetworkingManager = {
        let m = AHNetworkingManager()
        return m
    }()
    
    override init() {
        super.init()
        session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: myQueue)
    }
    
    
    /**普通的get请求，获取请求数据*/
    func get(URLString:String, succeed:SucceedHandler?, failed:FailedHandler?) -> NSURLSessionTask {
        
        let dataTask = self.dataTask(Method.GET, URLString: URLString, succeed: succeed, failed: failed)
        dataTask.resume()
        return dataTask
    }
    
    /**下载请求，无需在成功之后做任何处理*/
    func get(URLString:String, finish:FinishDownloadBlock?, failed:FailedHandler?, downloadProgress:DownloadProgressBlock?) -> NSURLSessionDownloadTask {
        let downloadTask = self.downloadTask(Method.GET, URLString: URLString, succeed: nil, failed: failed, downloadProgress: downloadProgress, uploadProgress: nil, finish: finish)
        downloadTask.resume()
        return downloadTask
    }
    
    /**下载请求，在成功之后做一些特定的操作*/
    func get(URLString:String, success:SucceedHandler?, failed:FailedHandler?, downloadProgress:DownloadProgressBlock?,finish:FinishDownloadBlock?) -> NSURLSessionDownloadTask {
        let downloadTask = self.downloadTask(Method.GET, URLString: URLString, succeed: success, failed: failed, downloadProgress: downloadProgress, uploadProgress: nil, finish: finish)
        downloadTask.resume()
        return downloadTask
    }
}


extension AHNetworkingManager {
    func createRequest(URLString:String, method:Method) -> (NSMutableURLRequest){
        let request = NSMutableURLRequest(URL: NSURL(string: URLString)!)
        request.HTTPMethod = method.rawValue
        return request
    }
    
    //MARK: data task
    func dataTask(method:Method, URLString:String, succeed:SucceedHandler?, failed:FailedHandler?) -> NSURLSessionDataTask {
        
        let request = createRequest(URLString, method: method)
        
        var task:NSURLSessionDataTask?
        task = self.session!.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if let e = error {
                NSLog("fail with error:\(e.localizedDescription)")
                if let f = failed {
                    f(task,e)
                }
                return
            }
            if let s = succeed {
                s(data, response)
            }
        }
        
        return task!
    }
    
    //MARK: download task
private func downloadTask(method:Method, URLString:String, succeed:SucceedHandler?, failed:FailedHandler?,downloadProgress:DownloadProgressBlock?, uploadProgress:UploadProgressBlock?, finish:FinishDownloadBlock?) -> NSURLSessionDownloadTask {
    
    let task = downloadTask(method,URLString: URLString,
        downloadProgress: downloadProgress,uploadProgress: nil,
        finish: finish,completion:{ (task,respobseObj:AnyObject?, error) -> Void in
        if error != nil {
            NSLog("fail with error:\(error)")
            if let f = failed {
                f(task,error)
            }
            return
        }
        if let s = succeed {
            s(respobseObj as? NSData,task.response)
        }
    })
    
    return task
}
    
    private func downloadTask(method:Method,
                           URLString:String,
                    downloadProgress:DownloadProgressBlock?,
                      uploadProgress:UploadProgressBlock?,
                              finish:FinishDownloadBlock?,
                        completion:CompletionBlock?) -> NSURLSessionDownloadTask {
        
        let request = createRequest(URLString, method: method)
        let task = self.session!.downloadTaskWithRequest(request)
        
        if let d = downloadProgress {
            self.downloadProgressHandler = d
        }
        
        if let u = uploadProgress {
            self.uploadProgressHandler = u
        }
        
        if let f = finish {
            self.finishHandler = f
        }
        
        if let c = completion {
            self.completionHandler = c
        }
        
        return task
    }
}

let group = dispatch_group_create()
let queue = dispatch_get_global_queue(0, 0)
extension AHNetworkingManager {
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let p = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        NSLog("progress:\(p)")
        
        if let progressHandler = self.downloadProgressHandler {
            progressHandler(downloadTask,bytesWritten: bytesWritten,totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        NSLog("resume succeed")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let distination = savePathForDownloadData(location, task: downloadTask)
        NSLog("distination:\(distination)")
        if let finish = self.finishHandler {
            finish(downloadTask, distinationURL: distination)
        }
        dispatch_group_async(group, queue) { () -> Void in
            self.responseObj = NSData(contentsOfURL: distination)
        }
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    
        dispatch_group_notify(group, queue) { () -> Void in
            if let complete = self.completionHandler {
                complete(task, responseObj: self.responseObj, error: error)
            }
        } 
    }
    
    //MARK: save downloaded data then return save path
    func savePathForDownloadData(location:NSURL, task:NSURLSessionDownloadTask) -> NSURL {
        let manager = NSFileManager.defaultManager()
        let docDict = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let originURL = task.originalRequest?.URL
        let distinationURL = docDict?.URLByAppendingPathComponent((originURL?.lastPathComponent)!)
        
        do{
            try manager.removeItemAtURL(distinationURL!)
        }catch{
            NSLog("remove failed")
        }
        
        do{
            try manager.copyItemAtURL(location, toURL: distinationURL!)
        }catch{
            NSLog("copy failed")
        }
        
        return distinationURL!
    }
}