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
    
    
}
