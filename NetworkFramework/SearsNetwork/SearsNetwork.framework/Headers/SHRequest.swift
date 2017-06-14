//
//  SHRequest.swift
//
//  Created by M, Vijayaragavan (Contractor) on 6/6/17.
//  Copyright © 2017 Furqan Kamani. All rights reserved.
//

import UIKit

public enum Method: String {
    case GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

public enum ParameterEncoding {
    case url
    case urlEncodedInURL
    case json
}

@objc public class SHRequest: NSObject {
    
    var url:URL? = nil
    
    private var parameterEncoding: ParameterEncoding = .json {
        didSet {
            
            var headerFields:[String:String] = [:]
            switch parameterEncoding {
            case .url, .urlEncodedInURL:
                headerFields["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
                
            case .json:
                headerFields["Accept"] = "application/json"
                headerFields["Content-Type"] = "application/json"
            }
            
//            if let sessionKey = KeychainWrapper.stringForKey(keyName: kSHSessionKey) {
//                headerFields["sessionKey"] = sessionKey
//            }
//            
            headerValues = headerFields
        }
    }
    
    var httpMethod:Method = .GET
    
    var parserSelector:Selector? = nil
    
    public var requestID:Int = 0
    
    var httpBody:Data? = nil
    
    public var headerValues:[String:String]? = nil
    
    var isCancelled:Bool = false
    
    private weak var sessionTask:URLSessionTask? = nil
    
    private weak var dispatchGroup:DispatchGroup? = nil
    
    private weak var dispatchWorkItem:DispatchWorkItem? = nil
    
    
    public init(_ url:URL,httpBody: [String: Any]?,parameterEncoding:ParameterEncoding = .json,httpMethod:Method,parserSelector:Selector?,requestID:Int = 0) {
        super.init()
        self.inizialize(url, httpBody: httpBody, parameterEncoding: parameterEncoding, httpMethod: httpMethod, parserSelector: parserSelector,requestID: requestID)
        
        
    }
    
    func inizialize(_ url:URL,httpBody: [String: Any]?,parameterEncoding:ParameterEncoding,httpMethod:Method,parserSelector:Selector?,requestID:Int = 0){
        self.url = url
        self.parameterEncoding = parameterEncoding
        self.httpMethod = httpMethod
        self.parserSelector = parserSelector
        self.requestID = requestID
        if let httpBodyParams = httpBody {
            if let parametersData = encodedParameters(httpBodyParams) {
                self.httpBody = parametersData
            }
        }
    }
    
    func encodedParameters(_ parameters: Any) -> Data? {
        var data: Data? = nil
        
        switch parameterEncoding {
        case .url, .urlEncodedInURL:
            let encodedParameters = query(parameters as! [String : Any])
            data = encodedParameters.data(using: String.Encoding.utf8)
            
        case .json:
            
            do {
                let options = JSONSerialization.WritingOptions()
                data = try JSONSerialization.data(withJSONObject: parameters, options: options)
                
            } catch {
                
            }
        }
        
        return data
    }
    
    func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(key, value)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }
    
    func queryComponents(_ key: String, _ value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    
    func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        let allowedCharacterSet = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharacters(in: generalDelimitersToEncode + subDelimitersToEncode)
        
        var escaped = ""
        
        escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) ?? string
        return escaped
    }
    
    
    func addRequestReference(block:DispatchWorkItem,dispatchGroup:DispatchGroup) {
        dispatchWorkItem =  block
        self.dispatchGroup = dispatchGroup
    }
    
    
    func addRequestReference(sessionTask:URLSessionTask) {
        self.sessionTask =  sessionTask
    }
    
    
   public func cancelRequest() {
        if let requestTask = sessionTask {
            requestTask.cancel()
            isCancelled = true
        }else if let dispatchBlock = dispatchWorkItem,let dispatchGroup = dispatchGroup {
            dispatchBlock.cancel()
            dispatchGroup.leave()
            isCancelled = true
        }
      
        
    }
    
    
   public func resumeRequest() {
        if let requestTask = sessionTask {
            requestTask.resume()
            isCancelled = false
        }
    }
    
}
