//
//  File.swift
//  
//
//  Created by zhtut on 2023/9/15.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 网络错误
public enum NetworkError: Error {
    /// 返回时出现参数错误
    case wrongResponse
    /// 返回时resonse不是http的
    case responseNotHttp
}

public class Networking {
    
    public static let shared = Networking()
    
    public var encryptHandler: ((URLRequest) throws -> URLRequest)?
    public var decryptHandler: ((Response) throws -> Response)?
    
    public var session = URLSession.shared
    
    /// 接口请求超时时间
    public var timeOut: TimeInterval = 10.0
    
    /// 资源超时时间
    public var resourceTimeOut: TimeInterval = 60.0
    
    /// 基础url
    public var baseURL = ""
    
    func send(request: URLRequest) async throws -> (Data, URLResponse) {
#if os(macOS) || os(iOS)
        return try await session.data(for: request)
#else
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let data, let response {
                    continuation.resume(returning: (data, response))
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NetworkError.wrongResponse)
                }
            }
            task.resume()
        }
#endif
    }
    
    /// 发送请求
    /// - Parameter request: 请求对象
    /// - Returns: 返回请求响应对象
    public func send(request: Request) async throws -> Response {
        var newRequest = request
        var urlRequest = try newRequest.createURLRequest(baseURL)
        newRequest.start = Date().timeIntervalSince1970 * 1000.0
        if let encryptHandler {
            // 如果有加密，先调用加密
            urlRequest = try encryptHandler(urlRequest)
        }
        newRequest.urlRequest = urlRequest
        let sendRequest = newRequest
        do {
            let (data, response) = try await send(request: urlRequest)
            guard let response = response as? HTTPURLResponse else {
                throw NetworkError.responseNotHttp
            }
            var res = Response(request: sendRequest,
                               body: data,
                               urlResponse: response)
            
            // 如果配置有解密方法，则优先用解密方法解密一下
            if res.succeed, let decryptHandler = decryptHandler {
                let de = try decryptHandler(res)
                res = de
            }
            
            // 解析Model
            if res.succeed, let _ = sendRequest.modelType {
                try? await res.decodeModel()
            }
            
            if sendRequest.printLog {
                res.log()
            }
            
            return res
        } catch {
            if sendRequest.printLog {
                Task {
                    var message = sendRequest.log
                    var duration = -1.0
                    if let start = sendRequest.start {
                        duration = Date().timeIntervalSince1970 * 1000.0 - start
                    }
                    message.append("\n------Error:\(duration)ms\n")
                    message.append("\(error)\n")
                    message.append("End<<<<<<<<<<")
                    print("\(message)")
                }
            }
            throw error
        }
    }
}
