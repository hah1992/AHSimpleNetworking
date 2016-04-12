//
//  DataTaskViewController.swift
//  NSURLSessionDemo
//
//  Created by hah on 16/4/8.
//  Copyright © 2016年 nuclear. All rights reserved.
//

import UIKit

class DataTaskViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    var data:NSData?
    var response:NSURLResponse?
    
    let URLString = "http://www.21cn.com/api/client/v2/getClientArticleList.do?userSerialNumber=85d3bbb95d03920e3c53d3801781c806&accessToken=&pageSize=1&hasImg=0&articleType=0&listIds=711r,846r,1235r"
    
    var callback:((data:NSData, response:NSURLResponse)->())?
    var models = [Model]()
    
    lazy var tableView:UITableView = {
        let t = UITableView(frame:self.view.bounds)
        t.delegate = self
        t.dataSource = self
        return t
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        
        let manager = AHNetworkingManager.manager
        manager.get(URLString, succeed: { (data:NSData?, response:NSURLResponse?) -> Void in
            
                let arr = self.parseResponse(data!, response: response!)
                for dic in arr {
                    let model = Model(dic: dic)
                    self.models.append(model)
                }
                dispatch_async(dispatch_get_main_queue(),{ Void in
                    self.tableView.reloadData()
                })
            
            }, failed: {(task,error) -> Void in
                NSLog("请求失败，reason:\(error?.localizedDescription)")
        })
    }
    
    func parseResponse(data:NSData, response:NSURLResponse) -> [[String:AnyObject]] {

        let d = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
        let info = d?.valueForKey("Rows") as! [[String:AnyObject]]
        
        return info
    }
    
    //MARK: - tableview datasource and delegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.models.count
    }
    
    let ID = "com.sessionDemo.dataTask"
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(ID)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: ID)
        }
        
        let info = self.models[indexPath.row]
        cell?.textLabel?.text = info.title
        
        return cell!
    }
}
