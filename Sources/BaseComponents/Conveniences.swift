//
//  Conveniences.swift
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

@objc
public enum UIColorTarget: Int {
    case background
    case layerBackground
    case text
}

public struct UICustomFontStyle: OptionSet {
    public let rawValue: Int
    public static let bold = UICustomFontStyle(rawValue: 1 << 0)
    public static let italic = UICustomFontStyle(rawValue: 1 << 1)
    public static let monoSpace = UICustomFontStyle(rawValue: 1 << 2)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension UIFont {
    static func size(_ textStyle: UIFont.TextStyle, _ fontStyle: UICustomFontStyle = []) -> UIFont {
        var font = UIFont.preferredFont(forTextStyle: textStyle)
        if (fontStyle != []) {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if fontStyle.contains(.bold) {
                traits.insert(.traitBold)
            }
            if fontStyle.contains(.italic) {
                traits.insert(.traitItalic)
            }
            if fontStyle.contains(.monoSpace) {
                traits.insert(.traitMonoSpace)
            }
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
            font = UIFont(descriptor: descriptor!, size: 0)
        }
        return font
    }
}

public extension UILabel {
    convenience init(_ text: String) {
        self.init()
        self.text = text
        lines(0)
    }
    
    @discardableResult
    func align(_ textAlignment: NSTextAlignment) -> Self {
        self.textAlignment = textAlignment
        return self
    }
    
    @discardableResult
    override func color(_ target: UIColorTarget, _ color: UIColor) -> Self {
        if (target == .text) {
            textColor = color
        } else {
            super.color(target, color)
        }
        return self
    }
    
    @discardableResult
    func lines(_ numberOfLines: Int) -> Self {
        self.numberOfLines = numberOfLines
        return self
    }
    
    @discardableResult
    func text(_ text: String?) -> Self {
        self.text = text
        return self
    }
    
    @discardableResult
    func size(_ textStyle: UIFont.TextStyle, _ fontStyle: UICustomFontStyle = []) -> Self {
        self.font = UIFont.size(textStyle, fontStyle)
        if #available(iOS 10.0, *) {
            adjustsFontForContentSizeCategory = true
        }
        return self
    }
    
    @discardableResult
    func size(using font: UIFont) -> Self {
        self.font = font
        return self
    }
}

public extension UITextField {
    convenience init(placeholder: String) {
        self.init()
        self.placeholder = placeholder
    }
    
    @discardableResult
    override func color(_ target: UIColorTarget, _ color: UIColor) -> Self {
        if (target == .text) {
            textColor = color
        } else {
            super.color(target, color)
        }
        return self
    }
    
    @discardableResult
    func align(_ textAlignment: NSTextAlignment) -> Self {
        self.textAlignment = textAlignment
        return self
    }
    
    @discardableResult
    func size(_ textStyle: UIFont.TextStyle, _ fontStyle: UICustomFontStyle = []) -> Self {
        self.font = UIFont.size(textStyle, fontStyle)
        if #available(iOS 10.0, *) {
            adjustsFontForContentSizeCategory = true
        }
        return self
    }
    
    @discardableResult
    func size(using font: UIFont) -> Self {
        self.font = font
        return self
    }
}

public extension UIView {
    @discardableResult @objc
    func color(_ target: UIColorTarget, _ color: UIColor) -> Self {
        switch target {
        case .background:
            backgroundColor = color
        case .layerBackground:
            layer.backgroundColor = color.cgColor
        default: break
        }
        return self
    }
    
}

public extension UIImage {
    static func imageFormColor(_ color: UIColor?) -> UIImage? {
        guard color != nil else {
            return nil
        }
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(color!.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public extension UIButton {
    convenience init(title: String, type: UIButton.ButtonType) {
        self.init(type: type)
        setTitle(title, for: .normal)
    }
    
    @discardableResult
    func size(_ textStyle: UIFont.TextStyle, _ fontStyle: UICustomFontStyle = []) -> Self {
        self.titleLabel?.font = UIFont.size(textStyle, fontStyle)
        if #available(iOS 10.0, *) {
            self.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        return self
    }
    
    @discardableResult
    func size(using font: UIFont) -> Self {
        self.titleLabel?.font = font
        return self
    }
    
    @discardableResult
    override func color(_ target: UIColorTarget, _ color: UIColor?) -> Self {
        return self.color(target, color, .normal)
    }
    
    @discardableResult
    func color(_ target: UIColorTarget, _ color: UIColor?, _ state: UIButton.State) -> Self {
        switch target {
        case .text:
            setTitleColor(color, for: state)
        case .background:
            if (state != .normal) {
                setBackgroundImage(UIImage.imageFormColor(color), for: state)
            } else {
                backgroundColor = color
            }
        default: break
        }
        
        return self
    }
    
    @discardableResult
    func text(_ text: String?, _ state: UIButton.State = .normal) -> Self {
        setTitle(text, for: state)
        return self
    }
}
