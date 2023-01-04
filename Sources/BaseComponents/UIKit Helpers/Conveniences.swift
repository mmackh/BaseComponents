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

#if os(iOS)

import UIKit

@objc
public enum UIColorTarget: Int {
    case background
    case layerBackground
    case text
}

public struct UICustomFontStyle: OptionSet {
    public let rawValue: Int
    public static let regular = UICustomFontStyle(rawValue: 0 << 0)
    public static let bold = UICustomFontStyle(rawValue: 1 << 0)
    public static let italic = UICustomFontStyle(rawValue: 1 << 1)
    public static let monoSpace = UICustomFontStyle(rawValue: 1 << 2)
    public static let monoSpaceDigit = UICustomFontStyle(rawValue: 1 << 3)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension UIFont {
    static func size(_ textStyle: UIFont.TextStyle, _ fontStyle: UICustomFontStyle = []) -> UIFont {
        if fontStyle.contains(.monoSpaceDigit) {
            let bodyMetrics = UIFontMetrics(forTextStyle: textStyle)
            return bodyMetrics.scaledFont(for: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: fontStyle.contains(.bold) ? .bold : .regular))
        }
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
            if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                font = UIFont(descriptor: descriptor, size: 0)
            }
        }
        return font
    }
}

public extension UIColor {
    static let hairline: UIColor = {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return .init(white: 0.79, alpha: 1)
        }
    }()
    
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection) -> UIColor in
                if (traitCollection.userInterfaceStyle == .dark) {
                    return dark
                }
                return light
            }
        }
        return light
    }
    
    convenience init(hex: UInt64) {
        let components = (r: CGFloat((hex >> 16) & 0xff) / 255, g: CGFloat((hex >> 08) & 0xff) / 255, b: CGFloat((hex >> 00) & 0xff) / 255)
        self.init(red: components.r, green: components.g, blue: components.b, alpha: 1.0)
    }
    
    convenience init(hex: String) {
        var hexCleaned = hex.replacingOccurrences(of: "#", with: "")
        if hexCleaned.count == 3 {
            var hexResult: String = ""
            for hexStringElement in hexCleaned {
                let hexString = String(hexStringElement)
                hexResult += hexString + hexString
            }
            hexCleaned = hexResult
        }
        if hexCleaned.count != 6 {
            hexCleaned = "FF0000"
        }
        var hexInt: UInt64 = 0
        Scanner(string: hexCleaned.uppercased()).scanHexInt64(&hexInt)
        self.init(hex: hexInt)
    }
    
    static func hex(_ hex: UInt64) -> UIColor {
        return UIColor(hex: hex)
    }
    
    static func hex(_ hex: String) -> UIColor {
        return UIColor(hex: hex)
    }
    
    func alpha(_ alpha: CGFloat) -> UIColor {
        return self.withAlphaComponent(alpha)
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
    func size(_ points: CGFloat, _ weight: UIFont.Weight = .regular) -> Self {
        self.font = UIFont.systemFont(ofSize: points, weight: weight)
        return self
    }
    
    @discardableResult
    func size(using font: UIFont) -> Self {
        self.font = font
        return self
    }
    
    @discardableResult
    func minimumScaleFactor(_ factor: CGFloat) -> Self {
        self.minimumScaleFactor = factor
        self.adjustsFontSizeToFitWidth = true
        return self
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
    func lineHeightMultiple(_ lineHeightMultiple: CGFloat) -> Self {
        self.lineHeightMultiple = lineHeightMultiple
        return self
    }
    
    @discardableResult
    func kern(_ kern: CGFloat) -> Self {
        self.kern = kern
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
    func size(_ points: CGFloat, _ weight: UIFont.Weight = .regular) -> Self {
        self.font = UIFont.systemFont(ofSize: points, weight: weight)
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
    func border(_ style: UITextField.BorderStyle) -> Self {
        self.borderStyle = style
        return self
    }
    
    @discardableResult
    override func align(_ textAlignment: NSTextAlignment) -> Self {
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
    func size(_ points: CGFloat, _ weight: UIFont.Weight = .regular) -> Self {
        self.font = UIFont.systemFont(ofSize: points, weight: weight)
        return self
    }
    
    @discardableResult
    func size(using font: UIFont) -> Self {
        self.font = font
        return self
    }
}

public extension UIView {
    @objc @discardableResult
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
    
    @discardableResult
    func tint(_ color: UIColor) -> Self {
        tintColor = color
        return self
    }
    
    @discardableResult
    func alpha(_ value: CGFloat) -> Self {
        alpha = value
        return self
    }
    
    @discardableResult
    func border(_ color: UIColor? = nil, width: CGFloat = 1.0, cornerRadius: CGFloat = 0.0) -> Self {
        if let color = color {
            layer.borderColor = color.cgColor
            layer.borderWidth = width
        }
        layer.cornerRadius = cornerRadius
        clipsToBounds = (cornerRadius > 0)
        return self
    }
    
    @discardableResult
    func cornerRadius(_ cornerRadius: CGFloat = 0.0) -> Self {
        layer.cornerRadius = cornerRadius
        clipsToBounds = (cornerRadius > 0)
        return self
    }
    
    @discardableResult
    func userInteractionEnabled(_ userInteractionEnabled: Bool) -> Self {
        isUserInteractionEnabled = userInteractionEnabled
        return self
    }
}

public extension UIImage {
    static func imageFormColor(_ color: UIColor?, size: CGSize = .init(width: 1, height: 1)) -> UIImage? {
        guard color != nil else {
            return nil
        }
        UIGraphicsBeginImageContext(size)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(color!.cgColor)
        ctx.fill(.init(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public extension UISearchBar {
    convenience init(placeholder: String) {
        self.init()
        self.placeholder = placeholder
    }
    
    @discardableResult
    override func color(_ target: UIColorTarget, _ color: UIColor?) -> Self {
        return self.color(target, color)
    }
    
    
}

public extension UIButton {
    convenience init(title: String, type: UIButton.ButtonType) {
        self.init(type: type)
        setTitle(title, for: .normal)
    }
    
    convenience init(_ title: String) {
        self.init(type: .system)
        setTitle(title, for: .normal)
    }
    
    convenience init(imageNamed: String, mode: UIView.ContentMode = .scaleAspectFit) {
        self.init(type: .system)
        imageView?.mode(mode)
        setImage(UIImage(named: imageNamed), for: .normal)
    }
    
    @available(iOS 13.0, *)
    convenience init(symbol: String, accessibility: String, weight: UIImage.SymbolWeight = .regular, mode: UIView.ContentMode = .center) {
        self.init(type: .system)
        setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(weight: weight)), for: .normal)
        
        imageView?.contentMode = .scaleAspectFit
        
        if mode == .scaleAspectFill {
            contentHorizontalAlignment = .fill
            contentVerticalAlignment = .fill
        }
        
        self.accessibility(accessibility)
    }
    
    @available(iOS 13.0, *)
    convenience init(symbol: String, accessibility: String, weight: UIImage.SymbolWeight = .regular, pointSize: CGFloat) {
        self.init(type: .system)
        setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight, scale: .default)), for: .normal)
        
        imageView?.contentMode = .scaleAspectFit
        
        self.accessibility(accessibility)
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
    func size(_ points: CGFloat, _ weight: UIFont.Weight = .regular) -> Self {
        self.titleLabel?.font = UIFont.systemFont(ofSize: points, weight: weight)
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
    
    @discardableResult
    func accessibility(_ value: String?) -> Self {
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 15.0, *) {
            for interaction in interactions {
                if let toolTipIntercation = interaction as? UIToolTipInteraction {
                    removeInteraction(toolTipIntercation)
                }
            }
            
            if let value = value, !value.isEmpty {
                addInteraction(UIToolTipInteraction(defaultToolTip: value))
            }
        }
        #else
        accessibilityLabel = value
        #endif
        return self
    }
}

public extension UIBarButtonItem {
    convenience init(_ title: String, style: UIBarButtonItem.Style = .plain) {
        self.init(title: title, style: style, target: nil, action: nil)
    }
}

public extension UIControl {
    @objc @discardableResult
    func align(_ textAlignment: NSTextAlignment) -> Self {
        switch textAlignment {
        case .left:
            self.contentHorizontalAlignment = .left
        case .right:
            self.contentHorizontalAlignment = .right
        default:
            self.contentHorizontalAlignment = .center
        }
        return self
    }
}

public extension UIImageView {
    enum Animation {
        case none
        case fade(TimeInterval)
    }
    
    private struct Static {
        static var ImageViewRequestKey = "fetchRequestImageViewKey"
        static let ImageViewQueue = DispatchQueue.init(label: "at.BaseComponents.UIImageView.Async")
        static let Cache: URLCache = {
            let cache = URLCache.shared
            cache.memoryCapacity = 50 * (1024 * 1024)
            cache.diskCapacity = 500 * (1024 * 1024)
            return cache
        }()
    }
    
    static func emptyRemoteImageCache() {
        Static.Cache.removeAllCachedResponses()
    }
    
    fileprivate func currentFetchRequest() -> NetFetchRequest? {
        return objc_getAssociatedObject(self, &Static.ImageViewRequestKey) as? NetFetchRequest
    }
    
    fileprivate func setCurrentFetchRequest(_ fetchRequest: NetFetchRequest?) {
        objc_setAssociatedObject(self, &Static.ImageViewRequestKey, fetchRequest, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @discardableResult
    func image(urlString: String, animation: UIImageView.Animation = .none, placeholderImage: UIImage? = nil, completionHandler: ((Bool)->())? = nil) -> Self {
        
        let currentRequest = currentFetchRequest()
        
        currentRequest?.cancel()
        
        func loadingComplete(success: Bool) {
            if let completionHandler = completionHandler {
                if Thread.isMainThread {
                    completionHandler(success)
                } else {
                    DispatchQueue.main.async {
                        completionHandler(success)
                    }
                }
            }
        }
        
        let request = NetFetchRequest(urlString: urlString) { [weak self] (response) in
            Static.ImageViewQueue.async {
                if let data = response.data {
                    if let image = UIImage(data: data) {
                        Static.Cache.storeCachedResponse(CachedURLResponse(response: response.urlResponse!, data: data, storagePolicy: .allowed), for: response.urlRequest!)
                        DispatchQueue.main.async {
                            if (response.urlString == self?.currentFetchRequest()?.urlString) {
                                switch animation {
                                case .none:
                                    self?.image = image
                                case .fade(let duration):
                                    guard let avSelf = self else { return }
                                    UIView.transition(with: avSelf, duration:duration, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
                                        avSelf.image = image
                                    }, completion: nil)
                                }
                                
                                loadingComplete(success: true)
                            }
                        }
                    }
                    else
                    {
                        loadingComplete(success: false)
                    }
                }
            }
        }
        image = placeholderImage
        request.cachePolicy = .returnCacheDataElseLoad
        request.ignoreQueue = true
        setCurrentFetchRequest(request)
        
        if let urlRequest = request.urlRequest(), let response = Static.Cache.cachedResponse(for: urlRequest), let image = UIImage(data: response.data) {
            if (urlRequest.url?.absoluteString == self.currentFetchRequest()?.urlString) {
                self.image = image
                loadingComplete(success: true)
            }
        } else {
            NetFetch.fetch(request, priority: true)
        }
        
        return self
    }
    
    @discardableResult
    func image(named: String) -> Self {
        image = UIImage(named: named)
        return self
    }
    
    @discardableResult
    func mode(_ mode: UIView.ContentMode) -> Self {
        contentMode = mode
        return self
    }
    
    @available(iOS 13.0, *)
    convenience init(symbol: String, weight: UIImage.SymbolWeight = .regular, pointSize: CGFloat? = nil) {
        self.init()
        
        let configuration: UIImage.SymbolConfiguration = {
            if let pointSize = pointSize {
                return UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
            }
            return  UIImage.SymbolConfiguration(weight: weight)
        }()
        
        self.image = UIImage(systemName: symbol, withConfiguration: configuration)
        
        self.contentMode = .scaleAspectFit
    }
}

public extension UIViewController {
    func embedInNavigationController(configurationHandler: ((UINavigationController)->())? = nil) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        if let configurationHandler = configurationHandler {
            unowned let weakNavigationController = navigationController
            configurationHandler(weakNavigationController)
        }
        return navigationController
    }
    
    var initialSafeAreaInsets: UIEdgeInsets {
        let safeAreaInsets = view.safeAreaInsets
        let additionalSafeAreaInsets = self.additionalSafeAreaInsets
        
        return UIEdgeInsets(top: safeAreaInsets.top - additionalSafeAreaInsets.top,
                            left: safeAreaInsets.left - additionalSafeAreaInsets.left,
                            bottom: safeAreaInsets.bottom - additionalSafeAreaInsets.bottom,
                            right: safeAreaInsets.right - additionalSafeAreaInsets.right)
    }
    
    var largeTitle: String? {
        get {
            title
        }
        set {
            title = newValue
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
}

@available(iOSApplicationExtension, unavailable)
public extension UIAlertController {
    static let dismissButtonIndex: Int = -1
    private static let destructiveOptionPrefix = "destructive://"
    
    static func show(style: UIAlertController.Style, title: String?, message: String?, options: Array<String>, dismiss: String, viewController: UIViewController? = nil, closure: ((_ buttonIdx: Int)->())?) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: style)
        for (idx, option) in options.enumerated() {
            let isDestructive = option.hasPrefix(UIAlertController.destructiveOptionPrefix)
            
            controller.addAction(UIAlertAction(title: isDestructive ? option.replacingOccurrences(of: UIAlertController.destructiveOptionPrefix, with: "") : option, style: isDestructive ? .destructive : .default , handler: { (action) in
                closure?(idx)
            }))
        }
        controller.addAction(UIAlertAction(title: dismiss, style: .cancel, handler: { (action) in
            closure?(UIAlertController.dismissButtonIndex)
        }))
        
        if let targetViewController = viewController ?? DebugController.currentViewController() {
            targetViewController.present(controller, animated: true, completion: nil)
        }
    }
    
    static func destructiveOption(_ value: String) -> String {
        UIAlertController.destructiveOptionPrefix + value
    }
}

public extension String {
    var destructiveOption: String {
        UIAlertController.destructiveOption(self)
    }
}

public extension Array {
    func fuzzySearch(_ searchText: String?, objectValueHandler: (Element) -> (String)) -> [Element] {
        guard let searchText = searchText?.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) else { return self }
        var greatMatches: [Element] = []
        var goodMatches: [Element] = []
        var fuzzyMatches: [Element] = []
        for obj in self {
            let objectValue = objectValueHandler(obj).lowercased().folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            
            if searchText.count > objectValue.count {
                continue
            }
            
            if objectValue.hasPrefix(searchText) || searchText == objectValue {
                greatMatches.append(obj)
                continue
            }
            
            if objectValue.contains(searchText) {
                goodMatches.append(obj)
                continue
            }
            
            let fuzzyText = searchText.replacingOccurrences(of: " ", with: "")
            
            var searchTextIdx = fuzzyText.startIndex, objectValueIdx = objectValue.startIndex
            let searchTextEndIdx = fuzzyText.endIndex, objectValueEndIdx = objectValue.endIndex
               
            var successfulMatch = true
            while searchTextIdx != searchTextEndIdx {
                if objectValueIdx == objectValueEndIdx {
                    successfulMatch = false
                    break
                }
                if fuzzyText[searchTextIdx] == objectValue[objectValueIdx] {
                    searchTextIdx = fuzzyText.index(after: searchTextIdx)
                }
                objectValueIdx = objectValue.index(after: objectValueIdx)
            }
            if successfulMatch {
                fuzzyMatches.append(obj)
            }
        }
        
        var matchesSorted: [Element] = []
        matchesSorted.append(contentsOf: greatMatches)
        matchesSorted.append(contentsOf: goodMatches)
        matchesSorted.append(contentsOf: fuzzyMatches)
        return matchesSorted
    }
}

public extension CGPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        CGPoint(x: x + dx, y: y + dy)
    }
}

public extension UIGestureRecognizer {
    func cancel() {
        state = .cancelled
        isEnabled = false
        isEnabled = true
    }
}

public class UILongPressPanGestureRecognizer: UIPanGestureRecognizer {
    public var minimumPressDuration: TimeInterval = 0.5
    private var minimumPressDurationTimer: Timer?
    
    public override var state: UIGestureRecognizer.State {
        didSet {
            if minimumPressDurationTimer != nil && state == .began {
                stopTimer()
            }
            if minimumPressDurationTimer != nil && (state == .failed || state == .cancelled || state == .ended) {
                stopTimer()
            }
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        self.minimumPressDurationTimer = Timer(timeInterval: minimumPressDuration, repeats: false) { [unowned self] (timer) in
            self.state = .began
        }
        RunLoop.current.add(self.minimumPressDurationTimer!, forMode: .common)
    }
    
    func stopTimer() {
        minimumPressDurationTimer?.invalidate()
        minimumPressDurationTimer = nil
    }
}

public extension UIScrollView {
    func scrollToTop(animated: Bool) {
        setContentOffset(.init(x: 0, y: safeAreaInsets.top > 0 ? -safeAreaInsets.top : 0), animated: animated)
    }
    
    func scrollToBottom(animated: Bool) {
        if contentSize.height < height { return }
        let offsetY = (contentSize.height - height + contentInset.bottom + contentInset.top)
        setContentOffset(.init(x: 0, y: offsetY), animated: animated)
    }
}

#endif

public extension Optional where Wrapped == Data {
    func bind<T: Codable>(_ model: T.Type, decoderHandler: ((JSONDecoder)->())? = nil, keyPath: String? = nil) -> T? {
        guard let self = self else { return nil }
        return self.bind(model, decoderHandler: decoderHandler, keyPath: keyPath)
    }
}

public extension Data {
    func bind<T: Codable>(_ model: T.Type, decoderHandler: ((JSONDecoder)->())? = nil, keyPath: String? = nil) -> T? {
        do {
            var data = self
            
            if let keyPath = keyPath, let dictionary = try JSONSerialization.jsonObject(with: self) as? NSDictionary, let result = dictionary.value(forKeyPath: keyPath) {
                data = try JSONSerialization.data(withJSONObject: result, options: .init())
            }
            
            let decoder = JSONDecoder()
            if let decoderHandler = decoderHandler {
                decoderHandler(decoder)
            }
            return try decoder.decode(model, from: data)
        } catch let parsingError {
            print("Binding error: ", parsingError)
        }
        return nil
    }
}
