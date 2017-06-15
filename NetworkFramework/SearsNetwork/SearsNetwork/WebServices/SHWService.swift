//
//  SHService.swift
//
//  Created by M, Vijayaragavan (Contractor) on 6/5/17.
//  Copyright © 2017 Furqan Kamani. All rights reserved.
//

import Foundation

class SHService:NSObject {
    
    var httpCode: Int = 200
    
    var error: NSError? = nil
    
    var result: AnyObject? = nil
    
    func processDataTaskService(request:SHRequest,referenceHandler: @escaping ( _ serviceTask: URLSessionTask) -> (), completionHandler: @escaping ( _ status: Bool) -> ()) {
        
        guard let _ = request.url else {
            return
        }
        
        var urlRequest = URLRequest(url: request.url!)
        urlRequest.httpMethod = request.httpMethod.rawValue
        urlRequest.httpBody =  request.httpBody
        
        if let headerFields = request.headerValues {
            
            for (key,value) in headerFields {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 45
        sessionConfiguration.timeoutIntervalForResource = 60
        
        let urlSession = URLSession(configuration: sessionConfiguration)
        
        let task = urlSession.dataTask(with: urlRequest) {
            (data, response, error) in
            
            if let resultData = data {
                let jsonString = String(data: resultData, encoding: String.Encoding.utf8)
                print(jsonString!)
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: resultData, options: .allowFragments)
                    self.result = jsonObject as AnyObject?
                } catch let error as NSError {
                    self.error = error
                }
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                self.httpCode = httpResponse.statusCode
            }
            
            if ((self.httpCode != 200 && self.httpCode != 204) || error != nil) {
                self.error = error as NSError?
                
                if self.httpCode >= 500 {
                    let userInfo = [NSLocalizedDescriptionKey: "Server response timed out. Please try later."]
                    let serverError = NSError(domain: "SLError", code: self.httpCode, userInfo: userInfo)
                    self.error = serverError
                }
                
                completionHandler(false)
                
            } else {
                completionHandler(true)
            }
        }
        referenceHandler(task)
        task.resume()
        
    }
    
}
