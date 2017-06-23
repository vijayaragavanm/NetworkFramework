//
//  SHWebServiceCalls.swift
//
//  Created by M, Vijayaragavan (Contractor) on 6/1/17.
//  Copyright © 2017 Furqan Kamani. All rights reserved.
//

import Foundation

private struct Constants {
    static let NSURLErrorCancelled  = -999
}

class SHWebServiceCalls {
    
    // MARK: - Data Task Service Call
    @discardableResult func dataTaskServiceRequest(_ request:SHRequest?,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (), completionHandler:@escaping (_ error: NSError?, _ responseObject: [String: Any]?) -> ()) {
        
        guard let requestObj = request,let _ = requestObj.url else {
            let error = NSError(domain: errorDomain, code: SHServiceErrorType.SHServiceErrorURLInvalid.rawValue, userInfo: [NSLocalizedDescriptionKey:ErrorDescription.urlNil])
            completionHandler(error, nil)
            return
        }
        
        let service = SHService()
        
        service.processDataTaskService(request:request!, referenceHandler: { (dataTask) in
            referenceHandler(dataTask )
        }) { (error,status) in
            self.parseResponse(service: service,error: error,status: status,completionHandler: completionHandler)
        }
    }
    
    
    // MARK: - Download Task Service Call
    @discardableResult func downloadTaskServiceRequest(_ request:SHRequest?,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (),dataProgressHandler:@escaping (_ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64,_ totalBytesWritten: Int64,_ totalBytesExpectedToWrite: Int64) -> (), completionHandler:@escaping (_ error: NSError?, _ responseObject: [String: Any]?) -> ()) {
        
        guard let requestObj = request,let _ = requestObj.url else {
            let error = NSError(domain: errorDomain, code: SHServiceErrorType.SHServiceErrorURLInvalid.rawValue, userInfo: [NSLocalizedDescriptionKey:ErrorDescription.urlNil])
            completionHandler(error, nil)
            return
        }
        
        let service = SHService()
        
        service.processDownloadTaskService(request: request!, referenceHandler: { (downloadTask) in
            referenceHandler(downloadTask)
        }, dataProgressHandler: { (downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            dataProgressHandler(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        }) { (error,status) in
            self.parseResponse(service: service,error: error,status: status,completionHandler: completionHandler)
        }
    }
    
    // MARK: - Upload Task Service Call
    @discardableResult func uploadTaskServiceRequest(_ request:SHRequest?,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (),dataProgressHandler:@escaping  (_ uploadTask: URLSessionTask, _ bytesSent: Int64,_ totalBytesSent: Int64,_ totalBytesExpectedToSend: Int64) -> (), completionHandler:@escaping (_ error: NSError?, _ responseObject: [String: Any]?) -> ()) {
        
        guard let requestObj = request,let _ = requestObj.url else {
            let error = NSError(domain: errorDomain, code: SHServiceErrorType.SHServiceErrorURLInvalid.rawValue, userInfo: [NSLocalizedDescriptionKey:ErrorDescription.urlNil])
            completionHandler(error, nil)
            return
        }
        
        let service = SHService()
        
        service.processUploadTaskService(request: request!, referenceHandler: { (uploadTask) in
            referenceHandler(uploadTask)
        }, dataProgressHandler: { (uploadTask, bytesSent, totalBytesSent, totalBytesExpectedToSend) in
            dataProgressHandler(uploadTask, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        }) { (error,status) in
            self.parseResponse(service: service,error: error,status: status,completionHandler: completionHandler)
        }
    }
    
    
    // MARK: - Handle Response,Error and Parse
    func parseResponse(service:SHService,error:NSError?,status:Bool,completionHandler:@escaping (_ error: NSError?, _ responseObject: [String: Any]?) -> ()) {
        if status {
            if var response = service.result as? [String: Any] {
                DispatchQueue.main.async {
                    response["httpStatusCode"] = String(service.httpCode) as AnyObject?
                    completionHandler(nil, response)
                }
                
            } else if service.httpCode == 204 || service.httpCode == 200 {
                DispatchQueue.main.async {
                    let responseDic = ["httpStatusCode": String(service.httpCode)]
                    completionHandler(nil, responseDic as [String: Any]?)
                }
            }
        }else {
            
            let serError: NSError? = self.parseOperationError(service)
            
            if let errorCode = serError?.code,errorCode != Constants.NSURLErrorCancelled {
                completionHandler(serError, nil)
            }
            
        }
    }
}


// MARK: - Handle Error and Parse
extension SHWebServiceCalls {
    
    func parseOperationError(_ operation: SHService) -> NSError {
        var message = "Unknown error occured"
        var error = getError(message, withErrorCode: operation.httpCode)
        
        if let serviceError = operation.error {
            error = serviceError
        }else {
            if let response = operation.result as? [String: Any] {
                if let msg = response["message"] as? String {
                    message = msg
                } else {
                    if let code = response["code"] as? String {
                        message = code
                    }
                }
                error = self.getError(message, withErrorCode: operation.httpCode)
                
            } else {
                error = self.getError(nil, withErrorCode: operation.httpCode)
            }
        }
        
        return error
    }
    
    
    func getError(_ message: String?, withErrorCode errorCode: Int) -> NSError {
        var errorMessage = "Unknown error occured"
        if let msg = message {
            errorMessage = msg
        }
        
        let userInfo = [NSLocalizedDescriptionKey: errorMessage]
        let serverError = NSError(domain: "SLError", code: errorCode, userInfo: userInfo)
        
        return serverError
    }
    
    
    func handleResponse(_ response: [String: Any]) -> (error: NSError?, result: Any?) {
        var serverError: NSError? = nil
        var serverResponse: Any? = nil
        
        if let status = response["status"] as? String {
            if status == "pass" {
                serverResponse = response as Any?
                
            } else {
                var errorMessage = "Unknown error occured"
                var errorCode = 500
                
                if let message = response["errorMessage"] as? String {
                    errorMessage = message
                }
                if let eCode = response["httpStatusCode"] as? Int {
                    errorCode = eCode
                }
                serverError = self.getError(errorMessage, withErrorCode: errorCode)
            }
        } else {
            let errorMessage = "Unknown error occured"
            let errorCode = 500
            serverError = self.getError(errorMessage, withErrorCode: errorCode)
        }
        
        return (serverError, serverResponse)
    }
    
}

