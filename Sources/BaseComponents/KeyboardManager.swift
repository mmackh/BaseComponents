//
//  KeyboardManager.swift
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

public enum KeyboardVisibility: Int {
    case visible
    case hidden
}

public class KeyboardManager: UIView {
 
    static var keyboardVisible : Bool = false

    weak public var rootView: UIView?
    weak public var resizableChildSplitView: SplitView?
    
    @discardableResult
    public static func manage(rootView: UIView, resizableChildSplitView: SplitView) -> KeyboardManager {
        let manager = KeyboardManager(rootView: rootView, resizableChildSplitView: resizableChildSplitView)
        rootView.addSubview(manager)
        manager.observeAndResize()
        return manager
    }
    
    public init(rootView: UIView, resizableChildSplitView: SplitView) {
        super.init(frame: CGRect.zero)
        self.rootView = rootView
        self.resizableChildSplitView = resizableChildSplitView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func visibility() -> KeyboardVisibility {
        if (keyboardVisible) {
            return .visible
        }
        return .hidden
    }
    
    private func observeAndResize() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector:#selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector:#selector(showKeyboard), name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector:#selector(showKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func showKeyboard(notificationObject: NSNotification) {
        let show = (notificationObject.name == UIResponder.keyboardDidShowNotification || notificationObject.name == UIResponder.keyboardWillShowNotification)
        
        KeyboardManager.keyboardVisible = show
        
        let keyboardFrame = (notificationObject.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let animationDuration = (notificationObject.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
        let animationCurve = (notificationObject.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.intValue ?? 0
        
        let masterFrame = rootView?.convert(rootView?.bounds ?? CGRect.zero, to: rootView?.window) ?? CGRect.zero
        
        let intersectionFrame = masterFrame.intersection(keyboardFrame)
        
        var splitViewFrame = resizableChildSplitView?.bounds
        
        splitViewFrame?.size.height =  !show ? rootView!.bounds.size.height : rootView!.bounds.size.height - intersectionFrame.size.height
        
        print(intersectionFrame)
        
        resizableChildSplitView?.frame = splitViewFrame!
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(animationCurve)), animations: {
            self.resizableChildSplitView?.invalidateLayout()
        }, completion: nil)
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
