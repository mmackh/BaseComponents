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



public class NetFetch {
    static private let session = URLSession(configuration: .default)
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
        if let request = queue.firstObject {
            submitRequest(request as! NetFetchRequest)
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
            
            if error != nil {
                if request.retryOnFailure {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        processQueue()
                    }
                    return
                } else {
                    DispatchQueue.main.async {
                        removeRequest(request)
                        processQueue()
                    }
                    return
                }
            }
            
            if let error = error {
                let bridgedError = error as NSError
                if bridgedError.code == NSURLErrorCancelled {
                    return
                }
            }
            
            let response = NetFetchResponse()
            response.data = data
            response.urlRequest = urlRequest
            response.urlResponse = urlResponse
            response.error = error
            response.url = urlRequest.url
            response.urlString = request.urlString

            DispatchQueue.main.async {
                request.completionHandler(response)
                if (queue.count > 0) {
                    queue.removeObject(at: 0)
                }
                processQueue()
                 
            }
        }
        request.dataTask!.resume()
    }
}
