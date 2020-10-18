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

open class NetFetchResponse {
    public var data: Data?
    public var urlRequest: URLRequest?
    public var urlResponse: URLResponse?
    public var error: Error?
    public var url: URL?
    public var urlString: String?
    
    public func string(encoding: String.Encoding = .utf8) -> String {
        if let data = data {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return ""
    }
    
    public func bind<T: Codable>(_ modelStruct: T.Type, decoderHandler: ((JSONDecoder)->())? = nil) -> T? {
        guard let data = data else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            if let decoderHandler = decoderHandler {
                decoderHandler(decoder)
            }
            return try decoder.decode(modelStruct, from: data)
        } catch let parsingError {
            print("Binding error: ", parsingError)
        }
        return nil;
    }
}

open class NetFetchRequest: Codable {
    public let urlString: String
    public var completionHandler: ((NetFetchResponse)->())? = nil
    
    public var httpMethod: String = "GET"
    public var parameters: Dictionary<String, String>? = nil
    public var body: Data? = nil
    public var headers: Dictionary<String, String>? = nil
    public var timeoutInterval: TimeInterval = 30.0
    public var cachePolicy: URLRequest.CachePolicy?
    public var retryOnFailure = false
    public var ignoreQueue = false
    public weak var dataTask: URLSessionDataTask?
    
    enum CodingKeys: String, CodingKey {
        case urlString
        case httpMethod
        case parameters
        case body
        case headers
        case timeoutInterval
        case cachePolicy
        case retryOnFailure
        case ignoreQueue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(httpMethod, forKey: .httpMethod)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(body, forKey: .body)
        try container.encode(headers, forKey: .headers)
        try container.encode(timeoutInterval, forKey: .timeoutInterval)
        try container.encode(cachePolicy?.rawValue, forKey: .cachePolicy)
        try container.encode(retryOnFailure, forKey: .retryOnFailure)
        try container.encode(ignoreQueue, forKey: .ignoreQueue)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        urlString = try values.decode(String.self, forKey: .urlString)
        httpMethod = try values.decode(String.self, forKey: .httpMethod)
        body = try values.decode(Data.self, forKey: .body)
        headers = try values.decode(Dictionary.self, forKey: .headers)
        timeoutInterval = try values.decode(TimeInterval.self, forKey: .timeoutInterval)
        cachePolicy = URLRequest.CachePolicy.init(rawValue: try values.decode(UInt.self, forKey: .urlString)) ?? .useProtocolCachePolicy
        retryOnFailure = try values.decode(Bool.self, forKey: .retryOnFailure)
        ignoreQueue = try values.decode(Bool.self, forKey: .ignoreQueue)
    }
    
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
        
        let requestCachePolicy: URLRequest.CachePolicy = {
            if let individualCachePolicy = self.cachePolicy {
                return individualCachePolicy
            } else {
                return NetFetch.cachePolicy
            }
        }()        
        
        var urlRequest = URLRequest(url: url, cachePolicy: requestCachePolicy, timeoutInterval: timeoutInterval)
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
    
    public func fetch() {
        NetFetch.fetch(self)
    }
}

open class NetFetch {
    static public var observer: ((_ request: NetFetchRequest,_ response: NetFetchResponse)->())? = nil
    static public var session = URLSession(configuration: .default)
    static public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    static private var queue: NSMutableArray = NSMutableArray()
    static private var currentTask: URLSessionDataTask?
    
    static public func fetch(_ request: NetFetchRequest, priority: Bool = false) {
        if (request.ignoreQueue) {
            submitRequest(request)
            return
        }
        if priority {
            queue.insert(request, at: 0)
        } else {
            queue.add(request)
        }
        processQueue()
    }
    
    static private func processQueue() {
        if let request = queue.firstObject as? NetFetchRequest {
            submitRequest(request)
        }
    }
    
    static fileprivate func removeRequest(_ request: NetFetchRequest) {
        queue.remove(request)
    }
    
    static private func submitRequest(_ request: NetFetchRequest) {
        
        guard let urlRequest = request.urlRequest() else {
            return
        }

        request.dataTask = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            func packageResponse() -> NetFetchResponse {
                let response = NetFetchResponse()
                response.data = data
                response.urlRequest = urlRequest
                response.urlResponse = urlResponse
                response.error = error
                response.url = urlRequest.url
                response.urlString = request.urlString
                return response
            }
            
            func respond() {
                let response = packageResponse()

                DispatchQueue.main.async {
                    if let observer = observer {
                        observer(request, response)
                    }
                    
                    if let completionHandler = request.completionHandler {
                        queue.remove(request)
                        processQueue()
                        
                        completionHandler(response)
                    } else {
                        queue.remove(request)
                        processQueue()
                    }
                }
            }
            
            if error != nil {
                if request.retryOnFailure {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        processQueue()
                    }
                    return
                } else {
                    respond()
                    return
                }
            }
            
            if let error = error {
                let bridgedError = error as NSError
                if bridgedError.code == NSURLErrorCancelled {
                    return
                }
            }
            respond();
        }
        request.dataTask!.resume()
    }
}
