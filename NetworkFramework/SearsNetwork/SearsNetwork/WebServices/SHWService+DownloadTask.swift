//
//  SHWService+DownloadTask.swift
//  SearsNetwork
//
//  Created by M, Vijayaragavan (Contractor) on 6/19/17.
//  Copyright © 2017 M, Vijayaragavan (Contractor). All rights reserved.
//

import UIKit

extension SHService {
    
    
    func processDownloadTaskService(request:SHRequest,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (),dataProgressHandler:@escaping (_ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64,_ totalBytesWritten: Int64,_ totalBytesExpectedToWrite: Int64) -> (), completionHandler: @escaping ( _ status: Bool) -> ()) {
        
        guard let _ = request.url else {
            return
        }
        self.dataProgressHandler = dataProgressHandler
        self.completionHandler = completionHandler
        
        self.filePath = request.filePath
        
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        let backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        
        downloadTask = backgroundSession.downloadTask(with: request.url!)
        referenceHandler(downloadTask)
        
        downloadTask.resume()
        
        
    }
}

extension SHService:URLSessionDownloadDelegate {
    
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL){
        
        if let destinationURLForFile = filePath {
            let fileManager = FileManager()
            
            if fileManager.fileExists(atPath: destinationURLForFile.path){
                do {
                    try fileManager.removeItem(at: destinationURLForFile)
                }catch{
                    if let completionHandler = completionHandler {
                        completionHandler(false)
                    }
                }
            }
            
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
            }catch{
                if let completionHandler = completionHandler {
                    completionHandler(false)
                }
            }
            
        }
        
    }
    
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64){
        if let dataDownloadProgress = self.dataProgressHandler {
            dataDownloadProgress(downloadTask,bytesWritten,totalBytesWritten,totalBytesExpectedToWrite)
        }
    }
    
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?){
        
        
        if let resultData = task.response {
            self.result = resultData
        }
        
        if let httpResponse = task.response as? HTTPURLResponse {
            self.httpCode = httpResponse.statusCode
        }
        
        if ((self.httpCode != 200 && self.httpCode != 204) || error != nil) {
            self.error = error as NSError?
            
            if self.httpCode >= 500 {
                let userInfo = [NSLocalizedDescriptionKey: "Server response timed out. Please try later."]
                let serverError = NSError(domain: "SLError", code: self.httpCode, userInfo: userInfo)
                self.error = serverError
            }
            
            if let completionHandler = completionHandler {
                completionHandler(false)
            }
            
        } else {
            if let completionHandler = completionHandler {
                completionHandler(true)
            }
        }
        
        uploadTask = nil
        downloadTask = nil
    }
    
}
