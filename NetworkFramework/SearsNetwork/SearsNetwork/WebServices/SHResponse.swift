//
//  SHResponse.swift
//
//  Created by M, Vijayaragavan (Contractor) on 6/6/17.
//  Copyright © 2017 Furqan Kamani. All rights reserved.
//

import UIKit

public protocol ResponseParserDelegate:class {
    func performParsing(shReponse:SHResponse?)
}

@objc public class SHResponse: NSObject {
    
    weak var responseParserDelegate: ResponseParserDelegate? = nil
    
    public var response: [String: Any]? = nil
    public var responseModel:Any? = nil
    public var requestID:Int = 0
    public var parserSelector:Selector? = nil
    
    init(_ response: [String: Any],networkTask:SHNetworkTask,mapperDelegate:ResponseParserDelegate?) {
        super.init()
        
        self.response = response
        if let requestID = networkTask.request?.requestID {
            self.requestID = requestID
        }
        self.parserSelector = networkTask.parserSelector
        self.responseParserDelegate = mapperDelegate
        
        //Calling mapper delegate
        if let delegate = responseParserDelegate {
            delegate.performParsing(shReponse: self)
        }
    }
    
}
   
