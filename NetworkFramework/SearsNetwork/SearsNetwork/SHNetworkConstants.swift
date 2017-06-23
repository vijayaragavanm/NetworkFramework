//
//  SHNetworkConstants.swift
//  SearsNetwork
//
//  Created by M, Vijayaragavan (Contractor) on 6/23/17.
//  Copyright © 2017 M, Vijayaragavan (Contractor). All rights reserved.
//

import Foundation

let errorDomain              = "com.Sears.SHErrorDomain"

struct ErrorDescription {
    static let urlNil                   = "URL Nil"
    static let filePathNil              = "FilePath Nil"
    static let uploadFileUnavailable     = "UploadFile Unavailable"
    static let unknownError             = "Unknown Error"
}

enum SHServiceErrorType: Int {
    case SHServiceErrorURLInvalid = -1989
    case SHServiceErrorFilePathNil
    case SHServiceErrorUploadFileUnavailable
    case SHServiceErrorUnkown
}

class SHNetworkConstants: NSObject {

}
