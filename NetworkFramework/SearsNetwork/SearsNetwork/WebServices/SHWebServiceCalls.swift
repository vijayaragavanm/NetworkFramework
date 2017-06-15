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
    
    // MARK: - Service Call
    @discardableResult func dataTaskServiceRequest(_ request:SHRequest?,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (), completionHandler:@escaping (_ error: NSError?, _ responseObject: [String: Any]?) -> ()) {
        
        guard let requestObj = request,let _ = requestObj.url else {
            return
        }
        
        let service = SHService()
        service.processDataTaskService(request:request!, referenceHandler: { (serviceTask) in
            referenceHandler(serviceTask )
        }) { (status) in
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
            } else {
                
                let serError: NSError? = self.parseOperationError(service)
                
                if let errorCode = serError?.code,errorCode != Constants.NSURLErrorCancelled {
                    completionHandler(serError, nil)
                }
                
            }
        }
        
    }
    
}


// MARK: - Handle Response,Error and Parse
extension SHWebServiceCalls {
    
    func getError(_ message: String?, withErrorCode errorCode: Int) -> NSError {
        var errorMessage = "Unknown error occured"
        if let msg = message {
            errorMessage = msg
        }
        
        let userInfo = [NSLocalizedDescriptionKey: errorMessage]
        let serverError = NSError(domain: "SLError", code: errorCode, userInfo: userInfo)
        
        return serverError
    }
    
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

