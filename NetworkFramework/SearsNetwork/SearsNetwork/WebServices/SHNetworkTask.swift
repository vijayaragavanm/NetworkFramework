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
    
    public var isCancelled:Bool {
        get {
            if let sessionTask = sessionTask,sessionTask.state == .canceling {
                return true
            }
            return false
        }
    }
    
    public var isPaused:Bool {
        get {
            if let sessionTask = sessionTask,sessionTask.state == .suspended {
                return true
            }
            return false
        }
    }
    
    public var isCompleted:Bool {
        get {
            if let sessionTask = sessionTask,sessionTask.state == .completed {
                return true
            }
            return false
        }
    }
    
    public var isInprogress:Bool {
        get {
            if let sessionTask = sessionTask,sessionTask.state == .running {
                return true
            }
            return false
        }
    }
    
    private weak var sessionTask:URLSessionTask? = nil
    
    private weak var dispatchGroup:DispatchGroup? = nil
    
    private weak var dispatchWorkItem:DispatchWorkItem? = nil
    
    public init(withUrl url:URL,httpBody: [String: Any]? = nil,parameterEncoding:ParameterEncoding = .json,httpMethod:Method = .GET,parserSelector:Selector? = nil,requestID:Int = 0,parserClass:Any? = nil,filePath:URL? = nil,uploadType:UploadType = .data,headerFields:[String:String]? = nil) {
        super.init()
        self.parserSelector = parserSelector
        self.parserClass = parserClass
        request?.inizializeRequest(url, httpBody: httpBody, parameterEncoding: parameterEncoding, httpMethod: httpMethod,requestID: requestID,filePath: filePath,uploadType:uploadType,headerFields:headerFields)
    }
    
    //MARK - Adding block operation reference - Batch request
    func addRequestReference(block:DispatchWorkItem,dispatchGroup:DispatchGroup) {
        dispatchWorkItem =  block
        self.dispatchGroup = dispatchGroup
    }
    
    //MARK - Adding sessinTask reference - Single request
    func addRequestReference(sessionTask:URLSessionTask) {
        self.sessionTask =  sessionTask
    }
    
    
    //MARK - Cancel Service Request
    public func cancelRequest() {
        
        if let requestTask = sessionTask {
            
            guard isCompleted == false else {
                return
            }
            
            requestTask.cancel()
            
        }else if let dispatchBlock = dispatchWorkItem,let dispatchGroup = dispatchGroup {
            dispatchBlock.cancel()
            dispatchGroup.leave()
            
        }
    }
    
    
    //MARK - Resume Service Request
    public func resumeRequest() {
        
        guard isPaused == true else {
            return
        }
        
        sessionTask?.resume()
            
    }
    
    //MARK - Pause Service Request
    public func pauseRequest() {
        
        guard isInprogress == true else {
            return
        }
        
        sessionTask?.suspend()
    }
    
    
}
