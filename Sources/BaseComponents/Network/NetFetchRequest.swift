
//
//  NetFetchRequest.swift
//  BaseComponents
//
//  Created by Marc Steven on 4.1.2020.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


import Foundation

public class NetFetchRequest {
    public let urlString: String
    public let completionHandler: ((NetFetchResponse)->())
    
    public var httpMethod: String = "GET"
    public var parameters: Dictionary<String, String>? = nil
    public var body: Data? = nil
    public var headers: Dictionary<String, String>? = nil
    public var timeoutInterval: TimeInterval = 30.0
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    public var retryOnFailure = false
    public var ignoreQueue = false
    public weak var dataTask: URLSessionDataTask?
    
    public init(urlString: String, completionHandler: @escaping((NetFetchResponse)->())) {
        self.urlString = urlString
        self.completionHandler = completionHandler
    }
    
    public func urlRequest() -> URLRequest? {
        var urlComponents = URLComponents(string: urlString)
        if let parameters = parameters {
            var queryItems: Array<URLQueryItem> = Array()
            parameters.forEach {
                queryItems.append(URLQueryItem(name: $0, value: $1))
            }
            urlComponents?.queryItems = queryItems
        }
        guard let url = urlComponents?.url else {
            return nil
        }
        var urlRequest = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        if let headers = headers {
            headers.forEach {
                urlRequest.setValue($1, forHTTPHeaderField: $0)
            }
        }
        urlRequest.httpMethod = httpMethod
        if let body = body {
            urlRequest.httpBody = body
        }
        return urlRequest
    }
    
    public func cancel() {
        if let task = dataTask {
            if task.state == .running {
                task.cancel()
            }
            if ignoreQueue {
                return
            }
        }
        
        NetFetch.removeRequest(self)
    }
}
