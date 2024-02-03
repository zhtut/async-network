//
//  File.swift
//
//
//  Created by zhtg on 2022/11/16.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 默认实现的一个Model
open class Response: Error {
    
    /// 请求成功的
    public init(request: Request,
                body: Data,
                urlResponse: HTTPURLResponse) {
        if let start = request.start {
            let duration = Date().timeIntervalSince1970 * 1000.0 - start
            self.duration = duration
        }
        self.request = request
        self.body = body
        self.urlResponse = urlResponse
    }

    /// 原始的网络请求，最终发出的网络请求就是这个
    open var request: Request

    /// 返回的data
    open var body: Data

    /// 原始返回的response对象，如果要查看网络请求的statusCode是不是200，可以在这查看，包括返回的header信息也在这里
    public var urlResponse: HTTPURLResponse
    
    /// 请求出结果花费了多少时间
    public var duration: TimeInterval?

    /// 解析的model对象，可能是数组或之类的
    public var model: Any?
}

public extension Response {
    /// 返回的字符串形式
    var bodyString: String? {
        let string = String(data: body, encoding: .utf8)
        return string
    }
    /// 返回的字符串形式
    func bodyString() async -> String? {
        bodyString
    }

    /// 返回的JSON格式
    var bodyJson: Any? {
        let json = try? JSONSerialization.jsonObject(with: body)
        return json
    }
    
    /// 返回的JSON格式
    func bodyJson() async -> Any? {
        bodyJson
    }
    
    var data: Any? {
        guard let json = bodyJson else {
            return nil
        }
        guard let key = request.dataKey,
              let dict = json as? [String: Any] else {
            return json
        }
        
        // 如果直接有data，则直接返回
        if let data = dict[key] {
            return data
        }
        
        if key.contains(".") {
            let arr = key.components(separatedBy: ".")
            var getDict: [String: Any]?
            for k in arr.dropLast() {
                getDict = dict[k] as? [String: Any]
                if getDict == nil {
                    return json
                }
            }
            if let last = arr.last,
               let data = getDict?[last] {
                return data
            }
        }
        
        return dict
    }

    /// 返回的Data数据，通过datakey获取的值，比如data.rows
    func data() async -> Any? {
        data
    }

    /// 请求是否成功
    var succeed: Bool {
        let statusCode = urlResponse.statusCode
        return statusCode >= 200 && statusCode < 300
    }
}

public extension Response {
    func decodeModel() async throws {
        guard let json = await data() else { return }
        guard let modelType = request.modelType else { return }
        if JSONSerialization.isValidJSONObject(json) {
            let jsonData = try JSONSerialization.data(withJSONObject: json)
            self.model = try JSONDecoder().decode(modelType.self, from: jsonData)
        }
    }
}

extension Response {
    /// 请求的日志信息，组装成crul命令了，可以复制到cmd中再次调用
    func curlLog() async -> String {
        let response = self
        var message = request.log
        message.append("\n------Response:\(response.duration ?? -1)ms\n")
        message.append("StatusCode:\(urlResponse.statusCode)\n")
        if let bodyString = await bodyString() {
            // 最长打印512个字符
            if bodyString.count > 10240 {
                message.append("\(bodyString.prefix(512))")
            } else {
                message.append("\(bodyString)")
            }
        }
        message.append("\nEnd<<<<<<<<<<")
        return message
    }

    /// 打印日志信息，方便查看问题
    public func log() {
        Task {
            let log = await curlLog()
            print("\(log)")
        }
    }
}

public extension TimeInterval {
    var dateDesc: String? {
        var interval = self
        if interval > 16312039620 {
            interval = interval / 1000.0
        }
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier:"Asia/Hong_Kong")!
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let str = formatter.string(from: date)
        return str
    }
}
