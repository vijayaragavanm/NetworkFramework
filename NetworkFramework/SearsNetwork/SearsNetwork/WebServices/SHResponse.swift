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
    private var request:SHRequest? = nil
    public var responseModel:Any? = nil
    public var requestID:Int = 0
    public var parserSelector:Selector? = nil
    
    init(_ response: [String: Any],request:SHRequest,mapperDelegate:ResponseParserDelegate) {
        super.init()
        
        self.response = response
        self.requestID = request.requestID
        self.request = request
        self.parserSelector = request.parserSelector
        self.responseParserDelegate = mapperDelegate
        if let delegate = responseParserDelegate {
            delegate.performParsing(shReponse: self)
        }
    }
    
}
