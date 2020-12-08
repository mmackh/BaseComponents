//
//  Geometry.swift
//  BaseComponents
//
//  Created by mmackh on 31.07.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

public extension CGRect {
    var x: CGFloat {
        get {
            origin.x
        }
        set {
            origin.x = newValue
        }
    }
    var y: CGFloat {
        get {
            origin.y
        }
        set {
            origin.y = newValue
        }
    }
    var isPortrait: Bool {
        get {
            height > width
        }
    }
    var isLandscape: Bool {
        get {
            height < width
        }
    }
}

public extension UIView {
    var x: CGFloat {
        get {
            frame.x
        }
        set {
            var frame = self.frame
            frame.x = newValue
            self.frame = frame
        }
    }
    
    var y: CGFloat {
        get {
            frame.y
        }
        set {
            var frame = self.frame
            frame.y = newValue
            self.frame = frame
        }
    }
    
    var width: CGFloat {
        get {
            frame.width
        }
        set {
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    
    var height: CGFloat {
        get {
            frame.height
        }
        set {
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    @discardableResult
    func frame(_ frame: CGRect) -> Self {
        self.frame = frame
        return self
    }
    
    @discardableResult
    func bounds(_ bounds: CGRect) -> Self {
        self.bounds = bounds
        return self
    }
    
    @discardableResult
    func x(_ x: CGFloat) -> Self {
        self.x = x
        return self
    }
    
    @discardableResult
    func y(_ y: CGFloat) -> Self {
        self.y = y
        return self
    }
    
    @discardableResult
    func width(_ width: CGFloat) -> Self {
        self.width = width
        return self
    }
    
    @discardableResult
    func height(_ height: CGFloat) -> Self {
        self.height = height
        return self
    }
}

public extension UIEdgeInsets {
    var horizontal: CGFloat {
        get {
            return left + right
        }
    }
    var vertical: CGFloat {
        get {
            return top + bottom
        }
    }
    
    init(padding: CGFloat) {
        self.init(top: padding, left: padding, bottom: padding, right: padding)
    }
    
    init(horizontal: CGFloat) {
        self.init(top: 0, left: horizontal, bottom: 0, right: horizontal)
    }
    
    init(vertical: CGFloat) {
        self.init(top: vertical, left: 0, bottom: vertical, right: 0)
    }
    
    init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
    
    init(top: CGFloat) {
        self.init(top: top, left: 0, bottom: 0, right: 0)
    }
    
    init(left: CGFloat) {
        self.init(top: 0, left: left, bottom: 0, right: 0)
    }
    
    init(bottom: CGFloat) {
        self.init(top: 0, left: 0, bottom: bottom, right: 0)
    }
    
    init(right: CGFloat) {
        self.init(top: 0, left: 0, bottom: 0, right: right)
    }
}

extension CGFloat {
    public static let onePixel: CGFloat = {
        return 1 / UIScreen.main.nativeScale
    }()
}

public class ManualFrameView: UIView {
    private let layoutSubviewsHandler: (_ view: ManualFrameView)->()
    
    public init(layoutSubviewsHandler: @escaping((_ view: ManualFrameView)->())) {
        self.layoutSubviewsHandler = layoutSubviewsHandler
        
        super.init(frame: .zero)
    }
    
    
    @available(*, unavailable)
    public override init(frame: CGRect) {
        self.layoutSubviewsHandler = { view in }
        
        super.init(frame: frame)
    }
    
    @available(*, unavailable)
    public init() {
        self.layoutSubviewsHandler = { view in }
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        unowned let weakSelf = self
        layoutSubviewsHandler(weakSelf)
    }
}
