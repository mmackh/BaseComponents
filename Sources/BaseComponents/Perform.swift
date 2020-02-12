//
//  Perform.swift
//  BaseComponents
//
//  Created by mmackh on 11.02.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

fileprivate struct SizeCache {
    var forSize: CGSize
    var calculatedSize: CGSize
}

public class PerformLabel: UIView {
    private let paragraphStyleMutable = NSMutableParagraphStyle()
    
    private var attributedString: NSAttributedString?
    private var attributedStringToDraw: NSAttributedString?
    
    private var frameCache: CGRect = .zero
    
    private var sizeCache: SizeCache?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        isOpaque = false
        isUserInteractionEnabled = false
        
        isAccessibilityElement = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize){
        didSet {
            setNeedsDisplay()
        }
    }
    
    open var text: String = "" {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override var accessibilityLabel: String? {
        get {
            return text
        }
        set {
        }
    }
    
    open var textAlignment: NSTextAlignment = .left {
        didSet {
            paragraphStyleMutable.alignment = textAlignment
            setNeedsDisplay()
        }
    }
    
    open var textColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var numberOfLines: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    fileprivate func composeAttributedStringToDraw() {
        if attributedStringToDraw != nil {
            return
        }
        
        self.attributedStringToDraw = attributedString
        if text.count > 0 {
            
            let totalRange = range()
            let mutableAttributedString = NSMutableAttributedString(string: text)
            if let textColor = textColor {
                mutableAttributedString.addAttribute(.foregroundColor, value: textColor, range: totalRange)
            } else {
                if #available(iOS 13.0, *) {
                    mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.label, range: totalRange)
                }
            }
            mutableAttributedString.addAttribute(.font, value: font, range: totalRange)
            mutableAttributedString.addAttribute(.paragraphStyle, value: paragraphStyleMutable, range: totalRange)
            
            self.attributedStringToDraw = mutableAttributedString
        }
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        composeAttributedStringToDraw()
        guard attributedStringToDraw != nil else {
            return .zero
        }
        if (sizeCache != nil && (sizeCache?.forSize.equalTo(size))!) {
            return sizeCache!.calculatedSize
        }
        
        let calculatedSize = attributedStringToDraw!.boundingRect(with: size, options: .usesLineFragmentOrigin, context: .none).integral.size
        sizeCache = SizeCache(forSize: size, calculatedSize: calculatedSize)
        return calculatedSize
    }
    
    public override func draw(_ rect: CGRect) {
        composeAttributedStringToDraw()
        guard attributedStringToDraw != nil else {
            return
        }
        let size = sizeThatFits(bounds.size)
        var targetRect = bounds
        if targetRect.size.height > size.height {
            targetRect.origin.y = (targetRect.size.height - size.height) / 2
        }
        attributedStringToDraw!.draw(in: targetRect)
    }
    
    public override func setNeedsDisplay() {
        attributedStringToDraw = nil
        sizeCache = nil
        super.setNeedsDisplay()
    }
    
    public override func layoutSubviews() {
        if frameCache.equalTo(frame) {
            return
        }
        frameCache = frame
        setNeedsDisplay()
    }
    
    fileprivate func range() -> NSRange {
        return .init(location: 0, length: text.count)
    }
}

public extension PerformLabel {
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
            return self
        }
        
        super.color(target, color)
        return self
    }
    
    @discardableResult
    func lines(_ numberOfLines: Int) -> Self {
        self.numberOfLines = numberOfLines
        return self
    }
    
    @discardableResult
    func text(_ text: String?) -> Self {
        self.text = text ?? ""
        return self
    }
    
    @discardableResult
    func size(_ textStyle: UIFont.TextStyle, _ fontStyle: UICustomFontStyle = []) -> Self {
        self.font = UIFont.size(textStyle, fontStyle)
        return self
    }
    
    @discardableResult
    func size(using font: UIFont) -> Self {
        self.font = font
        return self
    }
}
