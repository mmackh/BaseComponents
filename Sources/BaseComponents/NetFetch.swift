//
//  NetFetch.swift
//  BaseComponents
//
//  Created by mmackh on 27.12.19.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


import Foundation

public class NetFetchResponse {
    public var data: Data?
    public var urlResponse: URLResponse?
    public var error: Error?
    public var url: URL?
    
    public func string(encoding: String.Encoding = .utf8) -> String {
        if let data = data {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return ""
    }
    
    public func bind<T: Codable>(_ modelStruct: T.Type) -> T? {
        guard let data = data else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(modelStruct, from: data)
        } catch let parsingError {
            print("Binding error: ", parsingError)
        }
        
        return nil;
    }
}

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
    
    public init(urlString: String, completionHandler: @escaping((NetFetchResponse)->())) {
        self.urlString = urlString
        self.completionHandler = completionHandler
    }
}

public class NetFetch {
    static private let session = URLSession(configuration: .default)
    static private var queue: Array<NetFetchRequest> = []
    
    static public func fetch(_ request: NetFetchRequest) {
        if (request.ignoreQueue) {
            submitRequest(request)
            return
        }
        queue.append(request)
        processQueue()
    }
    
    static private func processQueue() {
        if let request = queue.first {
            submitRequest(request)
        }
    }
    
    static private func submitRequest(_ request: NetFetchRequest) {
        var urlComponents = URLComponents(string: request.urlString)
        if let parameters = request.parameters {
            var queryItems: Array<URLQueryItem> = Array()
            parameters.forEach {
                queryItems.append(URLQueryItem(name: $0, value: $1))
            }
            urlComponents?.queryItems = queryItems
        }
        guard let url = urlComponents?.url else {
            return
        }
        var urlRequest = URLRequest(url: url, cachePolicy: request.cachePolicy, timeoutInterval: request.timeoutInterval)
        if let headers = request.headers {
            headers.forEach {
                urlRequest.setValue($1, forHTTPHeaderField: $0)
            }
        }
        urlRequest.httpMethod = request.httpMethod
        if let body = request.body {
            urlRequest.httpBody = body
        }
        
        let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            if (error != nil && request.retryOnFailure){
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    processQueue()
                }
                return
            }
            
            DispatchQueue.main.async {
                let response = NetFetchResponse()
                response.data = data
                response.urlResponse = urlResponse
                response.error = error
                response.url = url
                request.completionHandler(response)
               
                queue.removeFirst()
                processQueue()
            }
        }
        task.resume()
    }
    
}
