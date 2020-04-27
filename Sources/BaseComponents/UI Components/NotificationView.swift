//
//  NotificationView.swift
//  BaseComponents
//
//  Created by mmackh on 26.04.20.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

public enum NotificationViewType {
    case info
    case alert
    case error
    case success
}

public enum NotificationViewPosition {
    case top
    case bottom
}

open class NotificationView: UIView {
    public static var bannerHorizontalPadding: CGFloat = 15.0
    public static var bannerCornerRadius: CGFloat = 12.0
    public static var bannerAdditionalYDistance: CGFloat = 10.0
    public static var bannerMaximumWidth: CGFloat = 400.0
    public static var bannerAdheresToSafeAreaInsets: Bool = true
    
    public static var font: UIFont = .size(.footnote, .bold)
    public static var messagePadding: CGFloat = 15.0
    
    public static var iconWidth: CGFloat = 30.0
    public static var iconMessageSpacing: CGFloat = 10.0
    
    public var position: NotificationViewPosition = .top
    public let messageLabel: UILabel = UILabel().lines(0)
    public var iconImageView: UIImageView?
    
    public var dismissed: Bool = false

    @discardableResult
    public static func show(_ type: NotificationViewType = .info, in view: UIView?, for duration: TimeInterval, message: String, position: NotificationViewPosition = .top, onTap: (()->())? = nil ) -> NotificationView? {
        guard let view = view else { return nil }
        
        let notificationView = NotificationView()
        notificationView.position = position
        notificationView.messageLabel.text = message
        notificationView.messageLabel.font = font
        notificationView.addSubview(notificationView.messageLabel)
        view.addSubview(notificationView)
        
        if #available(iOS 13.0, *) {
        } else {
            iconWidth = 0
        }
        
        if iconWidth > 0 {
            var iconName = ""
            switch type {
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
                notificationView.iconImageView = UIImageView(image: UIImage(systemName: iconName)).mode(.scaleAspectFit)
                notificationView.addSubview(notificationView.iconImageView!)
            }
        }
        
        
        notificationView.frame = notificationView.currentFrame()
        
        var foregroundColor: UIColor = .black
        if #available(iOS 13.0, *) {
            foregroundColor = .label
        }
        var iconColor: UIColor = .lightGray
        switch type {
        case .info:
            iconColor = .lightGray
        case .alert:
            iconColor = UIColor(red:1.00, green:0.80, blue:0.00, alpha:1.00)
        case .error:
            iconColor = UIColor(red:1.00, green:0.27, blue:0.23, alpha:1.00)
        case .success:
            iconColor = UIColor(red:0.20, green:0.78, blue:0.35, alpha:1.00)
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
        if #available(iOS 13.0, *) {
            notificationView.layer.borderColor = UIColor.separator.cgColor
        } else {
            notificationView.layer.borderColor = UIColor.init(white: 0.6, alpha: 0.4).cgColor
        }
        
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
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6, options: .allowUserInteraction, animations: {
            notificationView.transform = .identity
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            notificationView.dismiss()
        }
        
        return notificationView
    }
    
    func dismiss() {
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
    
    func currentFrame() -> CGRect {
        guard let superview = superview else { return .zero }
        
        let padding: CGFloat = NotificationView.bannerHorizontalPadding
        let width: CGFloat =  min(superview.bounds.size.width, NotificationView.bannerMaximumWidth) - (padding * 2)
        let x = (superview.bounds.size.width - width) / 2
        
        var notificationViewFrame: CGRect = .init(x: x, y: 0, width: width, height: 0)
        
        var messageLabelPaddingSize = notificationViewFrame.size
        messageLabelPaddingSize.width -= NotificationView.messagePadding * 2  + (NotificationView.iconWidth + NotificationView.iconMessageSpacing)
        
        let requiredMessageLabelSize = messageLabel.sizeThatFits(messageLabelPaddingSize)
        notificationViewFrame.size.height = requiredMessageLabelSize.height + (NotificationView.messagePadding * 2)
        
        var y: CGFloat = 0
        if position == .top {
            y = NotificationView.bannerAdheresToSafeAreaInsets ? superview.safeAreaInsets.top + NotificationView.bannerAdditionalYDistance : NotificationView.bannerAdditionalYDistance
        } else {
            y = superview.bounds.size.height - ((NotificationView.bannerAdheresToSafeAreaInsets ? (superview.safeAreaInsets.bottom + NotificationView.bannerAdditionalYDistance + notificationViewFrame.height) :  NotificationView.bannerAdditionalYDistance + notificationViewFrame.height))
        }
        notificationViewFrame.origin.y = y
        
        return notificationViewFrame
    }
    
    func hiddenTransform() -> CGAffineTransform {
        return position == .top ? .init(translationX: 0, y: -(self.frame.height + self.frame.origin.y)) : .init(translationX: 0, y: frame.height + (superview!.frame.height - self.frame.origin.y))
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        
        var messageLabelFrame = bounds.insetBy(dx: NotificationView.messagePadding, dy: NotificationView.messagePadding)
        messageLabelFrame.size.width -= (NotificationView.iconWidth + NotificationView.iconMessageSpacing)
        messageLabelFrame.origin.x += (NotificationView.iconWidth + NotificationView.iconMessageSpacing)
        messageLabel.frame = messageLabelFrame
        
        iconImageView?.frame = .init(x: NotificationView.messagePadding, y: 0, width: NotificationView.iconWidth, height: bounds.height)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.frame = self.currentFrame()
    }
}
