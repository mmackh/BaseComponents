//
//  NotificationView.swift
//  BaseComponents
//
//  Created by mmackh on 26.04.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#if os(iOS)

import UIKit

open class NotificationView: UIView {
    public enum Style {
        case info
        case alert
        case error
        case success
    }

    public enum Position {
        case top
        case bottom
    }
    
    public static var bannerHorizontalPadding: CGFloat = 15.0
    public static var bannerCornerRadius: CGFloat = 12.0
    public static var bannerAdditionalYDistance: CGFloat = 10.0
    public static var bannerMaximumWidth: CGFloat = 400.0
    public static var bannerAdheresToSafeAreaInsets: Bool = true
    
    public static var font: UIFont = .size(.footnote, .bold)
    public static var messagePadding: CGFloat = 15.0
    
    public static var iconWidth: CGFloat = 25.0
    public static var iconMessageSpacing: CGFloat = 10.0
    public static var iconImageProvider: ((Style)->(UIImage))? = nil
    public static var iconColorProvider: ((Style)->(UIColor))? = nil
    
    public var position: Position = .top
    public let messageLabel: UILabel = UILabel().lines(0)
    public var iconImageView: UIImageView?
    public var additionalYDistance: CGFloat = 0.0
    
    public var dismissed: Bool = false
    
    public var previousSuperviewWidth: CGFloat = 0

    @discardableResult
    public static func show(_ style: Style = .info, in view: UIView?, for duration: TimeInterval, message: String, position: Position = .top, onTap: (()->())? = nil ) -> NotificationView? {
        guard let view = view else { return nil }
        
        let notificationView = NotificationView()
        notificationView.position = position
        notificationView.messageLabel.text = message
        notificationView.messageLabel.font = font
        notificationView.addSubview(notificationView.messageLabel)
        notificationView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(notificationView)
        
        if #available(iOS 13.0, *) {
        } else if NotificationView.iconImageProvider == nil {
            NotificationView.iconWidth = 0
        }
        
        if let iconProvider = NotificationView.iconImageProvider {
            notificationView.iconImageView = UIImageView(image: iconProvider(style)).mode(.scaleAspectFit)
            notificationView.addSubview(notificationView.iconImageView!)
        } else if iconWidth > 0  {
            var iconName = ""
            switch style {
            case .info:
                iconName = "exclamationmark.circle"
            case .alert:
                iconName = "exclamationmark.triangle"
            case .error:
                iconName = "exclamationmark.octagon"
            case .success:
                iconName = "checkmark.circle"
            }
            
            if #available(iOS 13.0, *) {
                let iconImageView = UIImageView(image: UIImage(systemName: iconName)).mode(.scaleAspectFit)
                notificationView.iconImageView = iconImageView
                notificationView.addSubview(iconImageView)
            }
        }
        
        notificationView.frame = notificationView.currentFrame()
        
        var foregroundColor: UIColor = .black
        if #available(iOS 13.0, *) {
            foregroundColor = .label
        }
        var iconColor: UIColor = .lightGray
        if let iconColorProvider =  NotificationView.iconColorProvider {
            iconColor = iconColorProvider(style)
        } else {
            switch style {
            case .info:
                iconColor = .lightGray
            case .alert:
                iconColor = UIColor(red:1.00, green:0.80, blue:0.00, alpha:1.00)
            case .error:
                iconColor = UIColor(red:1.00, green:0.27, blue:0.23, alpha:1.00)
            case .success:
                iconColor = UIColor(red:0.20, green:0.78, blue:0.35, alpha:1.00)
            }
        }
        
        var blurEffect = UIBlurEffect(style: .regular)
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        }
        
        let backgroundView = UIVisualEffectView(effect: blurEffect)
        backgroundView.frame = notificationView.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.border(cornerRadius: NotificationView.bannerCornerRadius)
        notificationView.insertSubview(backgroundView, at: 0)
        
        notificationView.messageLabel.color(.text, foregroundColor)
        notificationView.iconImageView?.tintColor = iconColor
        notificationView.layer.cornerRadius = bannerCornerRadius
        
        let notificationViewLayer = notificationView.layer
        notificationViewLayer.shadowColor = UIColor(white: 0.3, alpha: 1.0).cgColor
        notificationViewLayer.shadowOpacity = 0.3
        notificationViewLayer.shadowOffset = .zero
        notificationViewLayer.shadowRadius = 10
        
        notificationView.layer.borderWidth = 1 / UIScreen.main.scale
        notificationView.layer.borderColor = UIColor.hairline.cgColor
        
        notificationView.transform = notificationView.hiddenTransform()
        
        if let onTap = onTap {
            notificationView.addGestureRecognizer(UITapGestureRecognizer({ (tap) in
                if tap.state == .recognized {
                    onTap()
                }
            }))
        }
        
        let swipeToDismissGesture = UISwipeGestureRecognizer { (dismiss) in
            notificationView.dismiss()
        }
        swipeToDismissGesture.direction = position == .top ? .up : .down
        notificationView.addGestureRecognizer(swipeToDismissGesture)
        
        let animationDuration: TimeInterval = 0.6
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
            notificationView.transform = .identity
        })
        
        if duration > 0.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + duration) {
                notificationView.dismiss()
            }
        }
        
        return notificationView
    }
    
    public func dismiss() {
        if dismissed {
            return
        }
        dismissed = true
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .allowUserInteraction, animations: {
            self.transform = self.hiddenTransform()
         }) { (complete) in
             if !complete {
                 return
             }
            self.removeFromSuperview()
         }
    }
    
    public func setIconImage(_ image: UIImage?) {
        iconImageView?.image = image
    }
    
    private func currentFrame() -> CGRect {
        guard let superview = superview else { return .zero }
        
        let padding: CGFloat = NotificationView.bannerHorizontalPadding
        var width: CGFloat =  min(superview.bounds.size.width, NotificationView.bannerMaximumWidth) - (padding * 2)
        
        let widthCalculation = (messageLabel.text! as NSString).size(withAttributes: [NSAttributedString.Key.font: messageLabel.font!]).width
        if widthCalculation < width - (NotificationView.iconWidth - NotificationView.iconMessageSpacing) {
            width = widthCalculation + NotificationView.iconWidth + NotificationView.iconMessageSpacing + (padding * 2)
        }
        
        let x = (superview.bounds.size.width - width) / 2
        
        var notificationViewFrame: CGRect = .init(x: x, y: 0, width: width, height: 0)
        
        var messageLabelPaddingSize = notificationViewFrame.size
        messageLabelPaddingSize.width -= NotificationView.messagePadding * 2  + (NotificationView.iconWidth + NotificationView.iconMessageSpacing)
        
        let requiredMessageLabelSize = messageLabel.sizeThatFits(messageLabelPaddingSize)
        notificationViewFrame.size.height = requiredMessageLabelSize.height + (NotificationView.messagePadding * 2)
        
        var y: CGFloat = 0
        if position == .top {
            y = NotificationView.bannerAdheresToSafeAreaInsets ? superview.safeAreaInsets.top + NotificationView.bannerAdditionalYDistance + additionalYDistance : NotificationView.bannerAdditionalYDistance + additionalYDistance
        } else {
            y = superview.bounds.size.height - ((NotificationView.bannerAdheresToSafeAreaInsets ? (superview.safeAreaInsets.bottom + NotificationView.bannerAdditionalYDistance + additionalYDistance + notificationViewFrame.height) :  NotificationView.bannerAdditionalYDistance + additionalYDistance + notificationViewFrame.height))
        }
        notificationViewFrame.origin.y = y
        
        return notificationViewFrame
    }
    
    private func hiddenTransform() -> CGAffineTransform {
        guard let superview = self.superview else { return .identity }
        return position == .top ? .init(translationX: 0, y: -(self.frame.height + self.frame.origin.y)) : .init(translationX: 0, y: frame.height + (superview.frame.height - self.frame.origin.y))
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if previousSuperviewWidth != superview?.bounds.width {
            self.frame = self.currentFrame()
            previousSuperviewWidth = superview?.bounds.width ?? 0
        }
        
        var messageLabelFrame = bounds.insetBy(dx: NotificationView.messagePadding, dy: NotificationView.messagePadding)
        messageLabelFrame.size.width -= (NotificationView.iconWidth + NotificationView.iconMessageSpacing)
        messageLabelFrame.origin.x += (NotificationView.iconWidth + NotificationView.iconMessageSpacing)
        messageLabel.frame = messageLabelFrame
        
        iconImageView?.frame = .init(x: NotificationView.messagePadding, y: 0, width: NotificationView.iconWidth, height: bounds.height)
    }
}

#endif
