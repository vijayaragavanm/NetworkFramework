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
    
    public var mapper:Any? = nil
    
    //service call for single request
    public func dataTaskRequest(request:SHRequest, completionHandler:@escaping (_ error: NSError?, _ responseObject: Any?) -> () ){
        
        serviceCaller.dataTaskServiceRequest(request, referenceHandler: { (serviceTask) in
            request.addRequestReference(sessionTask: serviceTask)
        }) { (error, response) in
            if error == nil {
                if let response = response {
                    DispatchQueue.global(qos: .background).async {
                        
                        var result:Any? = nil
                        
                        if let _ = request.parserSelector {
                            let response = SHResponse(response,request:request,mapperDelegate:self.mapper as! ResponseParserDelegate)
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
    
    
    //service call batch request
    public func batchDataTaskRequest(requestArray:[SHRequest], completionHandler:@escaping (_ error: NSError?, _ responseObject: Any?) -> (),_ groupCompletionHandler:@escaping () -> () ){
        
        var leaveGroupCount:Int = 0
        let taskGroup = DispatchGroup()
        
        var blocks: [DispatchWorkItem] = []
        
        for request in requestArray {
            
            taskGroup.enter()
            let block = DispatchWorkItem(flags: .inheritQoS) {
                
                self.serviceCaller.dataTaskServiceRequest(request, referenceHandler: { (serviceTask) in
                    
                    
                }) { (error, response) in
                    if error == nil {
                        if let response = response {
                            DispatchQueue.global(qos: .background).async {
                                
                                var result:Any? = nil
                                
                                if let _ = request.parserSelector {
                                    let response = SHResponse(response,request:request,mapperDelegate:self.mapper as! ResponseParserDelegate)
                                    result = response
                                }else {
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
            
            request.addRequestReference(block: block, dispatchGroup: taskGroup)
            blocks.append(block)
            
            DispatchQueue.global(qos: .background).async(execute:block)
            
        }
        
        taskGroup.notify(queue: DispatchQueue.main) {
            groupCompletionHandler()
            blocks.removeAll()
            
        }
    }
}
