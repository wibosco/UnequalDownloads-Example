//
//  URLRequest+HTTPBody.swift
//  DownloadStack-Example
//
//  Created by William Boles on 14/01/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

extension URLRequest {
    
    // MARK: - JSON
    
    mutating func setJSONParameters(_ parameters: [String: Any]?) {
        guard let parameters = parameters else {
            httpBody = nil
            return
        }
        
        httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions(rawValue: 0))
    }
}
