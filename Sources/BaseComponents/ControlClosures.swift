//
//  ControlClosures.swift
//  BaseComponents
//
//  Created by mmackh on 24.12.19.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

var closureCounter: Int = 0

@objc class ClosureContainer: NSObject {
    var closureControl: ((UIControl)->())?
    var closureGesture: ((UIGestureRecognizer)->())?
    var closureBarButtonItem: ((UIBarButtonItem)->())?
    weak var owner: AnyObject?
    var ID: String = ""

    override init () {
        self.ID = String(format: "controlClosure-%i", closureCounter)
        closureCounter += 1
    }

    @objc func invoke () {
        if let owner = owner {
            if let control = closureControl {
                control(owner as! UIControl)
            }
            if let gesture = closureGesture {
                gesture(owner as! UIGestureRecognizer)
            }
            if let barButtonItem = closureBarButtonItem {
                barButtonItem(owner as! UIBarButtonItem)
            }
        }
    }
}

fileprivate extension NSObject {
    func addClosureContainer(_ closureContainer: ClosureContainer) {
        objc_setAssociatedObject(self, &closureContainer.ID, closureContainer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

/*

 Generic Extensions
 
*/

public extension UIControl {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ control: UIControl)->()) -> Self {
        let closureContainer = ClosureContainer()
        closureContainer.closureControl = closure
        closureContainer.owner = self
        addTarget(closureContainer, action: #selector(ClosureContainer.invoke), for: controlEvents)
        self.addClosureContainer(closureContainer)
        return self
    }
}

public extension UIGestureRecognizer {
    convenience init(_ closure: @escaping (_ gesture: UIGestureRecognizer)->()) {
        self.init()
        let closureContainer = ClosureContainer()
        closureContainer.closureGesture = closure
        closureContainer.owner = self
        addTarget(closureContainer, action: #selector(ClosureContainer.invoke))
        addClosureContainer(closureContainer)
    }
}

public extension UIBarButtonItem {
    convenience init(barButtonSystemItem: UIBarButtonItem.SystemItem, _ closure: @escaping (_ barButtonItem: UIBarButtonItem)->()) {
        let closureContainer = ClosureContainer()
        closureContainer.closureBarButtonItem = closure
        self.init(barButtonSystemItem: barButtonSystemItem, target: closureContainer, action: #selector(ClosureContainer.invoke))
        closureContainer.owner = self
        addClosureContainer(closureContainer)
    }
    
    convenience init(title: String, style: UIBarButtonItem.Style, _ closure: @escaping (_ barButtonItem: UIBarButtonItem)->()) {
        let closureContainer = ClosureContainer()
        closureContainer.closureBarButtonItem = closure
        self.init(title: title, style: style, target: closureContainer, action: #selector(ClosureContainer.invoke))
        closureContainer.owner = self
        addClosureContainer(closureContainer)
    }
}

/*

 UITextField Extensions
 
*/

class TextFieldClosureContainer: ClosureContainer, UITextFieldDelegate {
    var shouldReturn: ((UITextField)->(Bool))?
    var shouldClear: ((UITextField)->(Bool))?
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let closure = shouldReturn {
            return closure(textField)
        }
        return false
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if let closure = shouldClear {
            return closure(textField)
        }
        return false
    }
}

public extension UITextField {
    @discardableResult
    func shouldReturn(_ closure: @escaping(_ control: UITextField)->(Bool)) -> Self {
        let closureContainer = TextFieldClosureContainer()
        closureContainer.shouldReturn = closure
        closureContainer.owner = self
        self.delegate = closureContainer
        self.addClosureContainer(closureContainer)
        return self
    }
    
    @discardableResult
    func shouldClear(_ closure: @escaping(_ control: UITextField)->(Bool)) -> Self {
        let closureContainer = TextFieldClosureContainer()
        closureContainer.shouldClear = closure
        closureContainer.owner = self
        self.delegate = closureContainer
        self.addClosureContainer(closureContainer)
        return self
    }
}
