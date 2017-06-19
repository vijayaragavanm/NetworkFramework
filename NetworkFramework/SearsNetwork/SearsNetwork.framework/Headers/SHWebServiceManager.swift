//
//  SHWebServiceManager.swift
//
//  Created by M, Vijayaragavan (Contractor) on 6/1/17.
//  Copyright © 2017 Furqan Kamani. All rights reserved.
//

import Foundation
import UIKit

@objc public class SHWebServiceManager:NSObject {
    
    lazy var serviceCaller: SHWebServiceCalls = {
        let caller = SHWebServiceCalls()
        
        return caller
    }()
    
    public static let shared : SHWebServiceManager = {
        let instance = SHWebServiceManager()
        return instance
    }()
    
    public var defaltMapper:Any? = nil
    
    //service call for single data task request
    public func dataTaskRequest(networkTask:SHNetworkTask, completionHandler:@escaping (_ error: NSError?, _ responseObject: Any?) -> () ){
        
        serviceCaller.dataTaskServiceRequest(networkTask.request, referenceHandler: { (serviceTask) in
            networkTask.addRequestReference(sessionTask: serviceTask)
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
    
    
    //service call batch data task request
    public func batchDataTaskRequest(networkTasks:[SHNetworkTask], completionHandler:@escaping (_ error: NSError?, _ responseObject: Any?) -> (),_ groupCompletionHandler:@escaping () -> () ){
        
        var leaveGroupCount:Int = 0
        let taskGroup = DispatchGroup()
        
        var blocks: [DispatchWorkItem] = []
        
        for networkTask in networkTasks {
            
            taskGroup.enter()
            let block = DispatchWorkItem(flags: .inheritQoS) {
                
                self.serviceCaller.dataTaskServiceRequest(networkTask.request, referenceHandler: { (serviceTask) in
                    
                    
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
                                } else {
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
