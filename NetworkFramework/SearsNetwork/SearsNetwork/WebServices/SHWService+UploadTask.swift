//
//  SHWService+UploadTask.swift
//  SearsNetwork
//
//  Created by M, Vijayaragavan (Contractor) on 6/21/17.
//  Copyright © 2017 M, Vijayaragavan (Contractor). All rights reserved.
//

import UIKit

extension SHService {
    
    
    func processUploadTaskService(request:SHRequest,uploadType:UploadType,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (),dataProgressHandler:@escaping (_ uploadTask: URLSessionTask, _ bytesSent: Int64,_ totalBytesSent: Int64,_ totalBytesExpectedToSend: Int64) -> (), completionHandler: @escaping ( _ status: Bool) -> ()) {
        
        guard let _ = request.url,let _ = request.filePath else {
            return
        }
        self.uploadDataProgressHandler = dataProgressHandler
        self.completionHandler = completionHandler
        
        self.filePath = request.filePath
       
        var uploadRequest = URLRequest(url: request.url!)
        request.httpMethod = .POST
        uploadRequest.httpMethod = request.httpMethod.rawValue
        uploadRequest.httpBody =  request.httpBody
        
        request.headerValues.forEach { (k,v) in uploadRequest.setValue(v, forHTTPHeaderField: k) }
        
        switch uploadType {
        case .data:
            
            let defaultSessionConfiguration = URLSessionConfiguration.default
            let defaultSession = Foundation.URLSession(configuration: defaultSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
            
            if let uploadData = try? Data(contentsOf: request.filePath!) {
                uploadRequest.setValue("\(uploadData.count)", forHTTPHeaderField: "Content-Length")
                uploadTask = defaultSession.uploadTask(with: uploadRequest as URLRequest, from: uploadData)
            }
          
        case .fileURL:
            let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
            let backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)

            uploadTask = backgroundSession.uploadTask(with: uploadRequest as URLRequest, fromFile: request.filePath!)
            
        case .stream:
            let defaultSessionConfiguration = URLSessionConfiguration.default
            let defaultSession = Foundation.URLSession(configuration: defaultSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
            uploadRequest.httpBodyStream =  InputStream(fileAtPath:(request.filePath?.path)!)
            uploadTask = defaultSession.uploadTask(withStreamedRequest: uploadRequest)
        }
        
        referenceHandler(uploadTask)
        
        uploadTask.resume()
        
    }
}

extension SHService:URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    {
        if let uploadDownloadProgress = self.uploadDataProgressHandler {
            uploadDownloadProgress(task,bytesSent,totalBytesSent,totalBytesExpectedToSend)
        }
    }

}
