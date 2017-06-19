//
//  SHRequest.swift
//  SearsNetwork
//
//  Created by M, Vijayaragavan (Contractor) on 6/15/17.
//  Copyright © 2017 M, Vijayaragavan (Contractor). All rights reserved.
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

class SHRequest: NSObject {
    
    var url:URL? = nil
    
    var httpMethod:Method = .GET
    
    var httpBody:Data? = nil
    
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
            
            headerValues = headerFields
        }
    }
    
    public var filePath:URL? = nil
    
    public var requestID:Int = 0
    
    public var headerValues:[String:String]? = nil
    
    func inizializeRequest(_ url:URL,httpBody: [String: Any]?,parameterEncoding:ParameterEncoding,httpMethod:Method,requestID:Int = 0,filePath:URL?){
        self.url = url
        self.parameterEncoding = parameterEncoding
        self.httpMethod = httpMethod
        self.requestID = requestID
        
        if let httpBodyParams = httpBody {
            if let parametersData = encodedParameters(httpBodyParams) {
                self.httpBody = parametersData
            }
        }
        
        self.filePath = filePath
        
    }
    
    
    //MARK - Encode parameters
    func encodedParameters(_ parameters: Any) -> Data? {
        var data: Data? = nil
        
        switch parameterEncoding {
        case .url, .urlEncodedInURL:
            let encodedParameters = SHQueryComposer.query(parameters as! [String : Any])
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
    
}

//MARK - Compose query parameters
@objc public class SHQueryComposer:NSObject {
    
    public class func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(key, value)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }
    
    private class func queryComponents(_ key: String, _ value: Any) -> [(String, String)] {
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
    
    
    private class func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        let allowedCharacterSet = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharacters(in: generalDelimitersToEncode + subDelimitersToEncode)
        
        var escaped = ""
        
        escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) ?? string
        return escaped
    }
    
}
