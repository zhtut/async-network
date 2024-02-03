//
//  File.swift
//  
//
//  Created by tutuzhou on 2024/2/3.
//

import Foundation

public extension Request {
    var log: String {
        let urlStr = urlString ?? ""
        let headerFields = urlRequest?.allHTTPHeaderFields ?? header
        let method = urlRequest?.httpMethod ?? method.rawValue
        var message = ">>>>>>>>>>Start:\(start?.dateDesc ?? "")"
        message.append("\ncurl -X \(method) '\(urlStr)' \\")
        if let headerFields {
            for (key, value) in headerFields {
                message.append("\n -H '\(key): \(value)' \\")
            }
        }
        if method != "GET" {
            var httpBodyStr = ""
            if let body = urlRequest?.httpBody,
                let str = String(data: body, encoding: .utf8) {
                httpBodyStr = str
            } else if let params = params {
                httpBodyStr = paramsString
            }
            message.append("\n -d '\(httpBodyStr)' \\")
        }
        if message.hasSuffix("\\") {
            message = "\(message.prefix(message.count - 2))"
        }
        return message
    }
}
