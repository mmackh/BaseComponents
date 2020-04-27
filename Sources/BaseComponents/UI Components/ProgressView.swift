//
//  ProgressView.swift
//  BaseComponents
//
//  Created by mmackh on 25.04.20.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


import UIKit

public enum ProgressViewType {
    case fullscreenBlur
    case appleStyle
    case spinnerOnlyLarge
    case spinnerOnlySmall
}

public extension UIView {
    @discardableResult
    func showProgressView(_ show: Bool, type: ProgressViewType = .fullscreenBlur) -> ProgressView? {
        let existingProgressView = subviews.compactMap{$0 as? ProgressView}.first
        
        if !show {
            existingProgressView?.hide()
            return nil
        }
        
        if existingProgressView != nil {
            existingProgressView?.removeFromSuperview()
        }
        
        let progressView = ProgressView(superview: self, type: type)
        progressView.show()
        return progressView
    }
}

open class ProgressView: UIView {
    let type: ProgressViewType
    let spinner: UIActivityIndicatorView
    let backgroundView: UIView
    var spinnerBackgroundView: UIView?
    var color: UIColor = .lightGray {
        didSet {
            spinner.color = color
        }
    }
    private static var appleSpinnerTransform: CGAffineTransform = .init(scaleX: 0.94, y: 0.94)
    
    fileprivate init(superview: UIView, type: ProgressViewType) {
        self.type = type
        
        spinner = UIActivityIndicatorView(style: (type == .spinnerOnlySmall ? .gray : .whiteLarge))
        spinner.color = color
        spinner.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        if type == .fullscreenBlur {
            backgroundView = UIVisualEffectView(effect: nil)
        } else {
            backgroundView = UIView()
        }
        backgroundView.frame = superview.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        super.init(frame: superview.bounds)
        
        addSubview(backgroundView)
        
        spinner.center = center
        addSubview(spinner)
        
        autoresizingMask = backgroundView.autoresizingMask
        
        if type == .appleStyle {
            var effect = UIBlurEffect(style: .extraLight)
            if #available(iOS 13.0, *) {
                effect = UIBlurEffect(style: .systemThickMaterial)
            }
            
            let spinnerBackground = UIVisualEffectView(effect: effect)
            spinnerBackground.frame = .init(x: 0, y: 0, width: 150, height: 150)
            spinnerBackground.center = backgroundView.center
            spinnerBackground.autoresizingMask = spinner.autoresizingMask
            spinnerBackground.layer.cornerRadius = 12.0
            spinnerBackground.layer.masksToBounds = true
            backgroundView.addSubview(spinnerBackground)
            spinnerBackgroundView = spinnerBackground
        }
        
        superview.addSubview(self)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        if self.type == .appleStyle {
            spinnerBackgroundView?.alpha = 0.4
            spinner.alpha = 0.4
            
            spinnerBackgroundView?.transform = .init(scaleX: 1.1, y: 1.1)
            spinner.transform = .init(scaleX: 1.1, y: 1.1)
        }
        UIView.animate(withDuration: 0.3) {
            if self.type == .appleStyle {
                self.spinnerBackgroundView?.alpha = 1
                self.spinner.alpha = 1
                
                self.spinnerBackgroundView?.transform = .identity
                self.spinner.transform = .identity
                self.backgroundView.color(.background, .init(white: 0, alpha: 0.2))
            }
            
            if self.type == .fullscreenBlur {
                (self.backgroundView as? UIVisualEffectView)?.effect = UIBlurEffect.init(style: .regular)
            }
            self.spinner.startAnimating()
        }
        
    }
    
    func hide() {
        if type == .fullscreenBlur || type == .appleStyle {
            UIView.animate(withDuration: 0.3, animations: {
                if self.type == .fullscreenBlur {
                    self.spinner.alpha = 0
                    (self.backgroundView as? UIVisualEffectView)?.effect = nil
                } else {
                    self.spinnerBackgroundView?.transform = ProgressView.appleSpinnerTransform
                    self.spinnerBackgroundView?.alpha = 0.0
                    self.spinner.transform = ProgressView.appleSpinnerTransform
                    self.spinner.alpha = 0.0
                    self.backgroundView.color(.background, .clear)
                }
            }) { (done) in
                if !done {
                    return
                }
                self.removeFromSuperview()
            }
            return
        }
        self.spinner.stopAnimating()
        self.removeFromSuperview()
    }
    
    public override var tintColor: UIColor! {
        didSet {
            spinner.color = tintColor
        }
    }
    
}
