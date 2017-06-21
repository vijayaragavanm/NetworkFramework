//
//  SHWebServiceManager+UploadTask.swift
//  SearsNetwork
//
//  Created by M, Vijayaragavan (Contractor) on 6/21/17.
//  Copyright © 2017 M, Vijayaragavan (Contractor). All rights reserved.
//

import UIKit

extension SHWebServiceManager {
    
    //service call for single upload request
    public func uploadTaskRequest(networkTask:SHNetworkTask,uploadType:UploadType,dataProgressHandler:@escaping (_ uploadTask: URLSessionTask, _ didSendBodyData: Int64,_ totalBytesSent: Int64,_ totalBytesExpectedToSend: Int64) -> (), completionHandler:@escaping (_ error: NSError?, _ responseObject: Any?) -> () ){
        
        serviceCaller.uploadTaskServiceRequest(networkTask.request, uploadType: uploadType,referenceHandler: { (downloadTask) in
            networkTask.addRequestReference(sessionTask: downloadTask)
        }, dataProgressHandler: { (uploadTask, didSendBodyData, totalBytesSent, totalBytesExpectedToSend) in
            dataProgressHandler(uploadTask, didSendBodyData, totalBytesSent, totalBytesExpectedToSend)
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
