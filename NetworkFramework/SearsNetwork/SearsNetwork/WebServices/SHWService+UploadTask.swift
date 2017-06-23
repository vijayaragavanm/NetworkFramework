//
//  SHWService+UploadTask.swift
//  SearsNetwork
//
//  Created by M, Vijayaragavan (Contractor) on 6/21/17.
//  Copyright © 2017 M, Vijayaragavan (Contractor). All rights reserved.
//

import UIKit

extension SHService {
    
    
    func processUploadTaskService(request:SHRequest,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (),dataProgressHandler:@escaping (_ uploadTask: URLSessionTask, _ bytesSent: Int64,_ totalBytesSent: Int64,_ totalBytesExpectedToSend: Int64) -> (), completionHandler: @escaping (_ error:NSError?, _ status: Bool) -> ()) {
        
        guard let _ = request.url else {
            let error = NSError(domain: errorDomain, code:SHServiceErrorType.SHServiceErrorURLInvalid.rawValue, userInfo: [NSLocalizedDescriptionKey:ErrorDescription.urlNil])
            self.error = error
            completionHandler(error, false)
            return
        }
        
        guard let _ = request.filePath?.path else {
            let error = NSError(domain: errorDomain, code: SHServiceErrorType.SHServiceErrorFilePathNil.rawValue, userInfo: [NSLocalizedDescriptionKey:ErrorDescription.filePathNil])
            self.error = error
            completionHandler(error, false)
            return
        }
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: (request.filePath?.path)!) else {
            let error = NSError(domain: errorDomain, code: SHServiceErrorType.SHServiceErrorUploadFileUnavailable.rawValue, userInfo: [NSLocalizedDescriptionKey:ErrorDescription.uploadFileUnavailable])
            self.error = error
            completionHandler(error, false)
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
        
        switch request.uploadType {
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
