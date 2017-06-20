//
//  SHWebServiceManager+DownloadTask.swift
//  SearsNetwork
//
//  Created by M, Vijayaragavan (Contractor) on 6/19/17.
//  Copyright © 2017 M, Vijayaragavan (Contractor). All rights reserved.
//

import UIKit

extension SHWebServiceManager {
    
    //service call for single download request
    public func downloadTaskRequest(networkTask:SHNetworkTask,dataProgressHandler:@escaping (_ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64,_ totalBytesWritten: Int64,_ totalBytesExpectedToWrite: Int64) -> (), completionHandler:@escaping (_ error: NSError?, _ responseObject: Any?) -> () ){
        
        serviceCaller.downloadTaskServiceRequest(networkTask.request, referenceHandler: { (downloadTask) in
            networkTask.addRequestReference(sessionTask: downloadTask)
        }, dataProgressHandler: { (downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            dataProgressHandler(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        }) { (error, response) in
            if error == nil {
                if let response = response {
                    DispatchQueue.global(qos: .background).async {
                        
                        var result:Any? = nil
                        
                        if let parserClass = networkTask.parserClass {
                            let response = SHResponse(response,networkTask:networkTask,mapperDelegate:parserClass as? ResponseParserDelegate)
                            result = response
                        }else if let _ = networkTask.parserSelector,let defaultMapper = self.defaltMapper {
                            let response = SHResponse(response,networkTask:networkTask,mapperDelegate:defaultMapper as? ResponseParserDelegate)
                            result = response
                        }else {
                            result = response
                        }
                        
                        DispatchQueue.main.async {
                            completionHandler(nil,result)
                        }
                    }
                }
            } else {
                completionHandler(error, nil)
            }
        }
        
    }
    
    
    //service call batch download task request
    public func batchDownloadTaskRequest(networkTasks:[SHNetworkTask],dataProgressHandler:@escaping (_ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64,_ totalBytesWritten: Int64,_ totalBytesExpectedToWrite: Int64) -> (), completionHandler:@escaping (_ error: NSError?, _ responseObject: Any?) -> (),_ groupCompletionHandler:@escaping () -> () ){
        
        var leaveGroupCount:Int = 0
        let taskGroup = DispatchGroup()
        
        var blocks: [DispatchWorkItem] = []
        
        for networkTask in networkTasks {
            
            taskGroup.enter()
            let block = DispatchWorkItem(flags: .inheritQoS) {
                
                
                self.serviceCaller.downloadTaskServiceRequest(networkTask.request, referenceHandler: { (downloadTask) in
               
                }, dataProgressHandler: { (downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                    dataProgressHandler(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
                }) { (error, response) in
                    if error == nil {
                        if let response = response {
                            DispatchQueue.global(qos: .background).async {
                                
                                var result:Any? = nil
                                
                                if let parserClass = networkTask.parserClass {
                                    let response = SHResponse(response,networkTask:networkTask,mapperDelegate:parserClass as? ResponseParserDelegate)
                                    result = response
                                }else if let _ = networkTask.parserSelector,let defaultMapper = self.defaltMapper {
                                    let response = SHResponse(response,networkTask:networkTask,mapperDelegate:defaultMapper as? ResponseParserDelegate)
                                    result = response
                                }else {
                                    let response = SHResponse(response,networkTask:networkTask)
                                    result = response
                                }
                                
                                DispatchQueue.main.async {
                                    completionHandler(nil,result)
                                    
                                    let progressTaskCount = blocks.filter{!$0.isCancelled}.count
                                    
                                    if progressTaskCount > leaveGroupCount {
                                        
                                        leaveGroupCount += 1
                                        taskGroup.leave()
                                        
                                    }
                                }
                            }
                        }
                    } else {
                        completionHandler(error, nil)
                        
                        let progressTaskCount = blocks.filter{!$0.isCancelled}.count
                        
                        if progressTaskCount > leaveGroupCount {
                            leaveGroupCount += 1
                            taskGroup.leave()
                            
                        }
                    }
                }
            }
            
            networkTask.addRequestReference(block: block, dispatchGroup: taskGroup)
            blocks.append(block)
            
            DispatchQueue.global(qos: .background).async(execute:block)
            
        }
        
        taskGroup.notify(queue: DispatchQueue.main) {
            groupCompletionHandler()
            blocks.removeAll()
            
        }
    }
    
}
