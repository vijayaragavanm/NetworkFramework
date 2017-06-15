//
//  SHNetworkTask.swift
//
//  Created by M, Vijayaragavan (Contractor) on 6/6/17.
//  Copyright © 2017 Furqan Kamani. All rights reserved.
//

import UIKit



@objc public class SHNetworkTask: NSObject {
    
    lazy var request:SHRequest? = {
        return SHRequest()
    }()
    
    var parserClass:Any? = nil
    
    var parserSelector:Selector? = nil
    
    var isCancelled:Bool = false
    
    private weak var sessionTask:URLSessionTask? = nil
    
    private weak var dispatchGroup:DispatchGroup? = nil
    
    private weak var dispatchWorkItem:DispatchWorkItem? = nil
    
    public init(withUrl url:URL,httpBody: [String: Any]?,parameterEncoding:ParameterEncoding = .json,httpMethod:Method,parserSelector:Selector?,requestID:Int = 0,parserClass:Any? = nil) {
        super.init()
        self.parserSelector = parserSelector
        self.parserClass = parserClass
        request?.inizializeRequest(url, httpBody: httpBody, parameterEncoding: parameterEncoding, httpMethod: httpMethod,requestID: requestID)
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
