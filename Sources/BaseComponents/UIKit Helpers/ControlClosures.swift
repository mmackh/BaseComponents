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

#if os(iOS)

import UIKit

@objc
fileprivate class ClosureContainer: NSObject {
    var closureControl: ((UIControl)->())?
    var closureGesture: ((UIGestureRecognizer)->())?
    var closureBarButtonItem: ((UIBarButtonItem)->())?
    weak var owner: AnyObject?
    
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
        objc_setAssociatedObject(self, Unmanaged.passUnretained(closureContainer).toOpaque(), closureContainer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/*

 Generic Extensions
 
*/

fileprivate extension UIControl {
    @discardableResult
    func addGenericAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ control: UIControl)->()) -> Self {
        let closureContainer = ClosureContainer()
        closureContainer.closureControl = closure
        closureContainer.owner = self
        addClosureContainer(closureContainer)
        addTarget(closureContainer, action: #selector(ClosureContainer.invoke), for: controlEvents)
        return self
    }
}

public extension UIButton {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ button: UIButton) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UIButton)
        }
    }
}

public extension UITextField {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ textField: UITextField) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UITextField)
        }
    }
}

public extension UIRefreshControl {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ refreshControl: UIRefreshControl) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UIRefreshControl)
        }
    }
}

public extension UISegmentedControl {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ segmentedControl: UISegmentedControl) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UISegmentedControl)
        }
    }
}

public extension UISlider {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ slider: UISlider) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UISlider)
        }
    }
}

public extension UIStepper {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ stepper: UIStepper) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UIStepper)
        }
    }
}

public extension UISwitch {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ switch: UISwitch) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UISwitch)
        }
    }
}

public extension UIDatePicker {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ datePicker: UIDatePicker) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UIDatePicker)
        }
    }
}

public extension UIPageControl {
    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ pageControl: UIPageControl) -> ()) -> Self {
        return addGenericAction(for: controlEvents) { (control) in
            closure(control as! UIPageControl)
        }
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
    
    convenience init(image: UIImage?, style: UIBarButtonItem.Style, _ closure: @escaping (_ barButtonItem: UIBarButtonItem)->()) {
        let closureContainer = ClosureContainer()
        closureContainer.closureBarButtonItem = closure
        self.init(image: image, style: style, target: closureContainer, action: #selector(ClosureContainer.invoke))
        closureContainer.owner = self
        addClosureContainer(closureContainer)
    }
    
    @discardableResult
    func addAction( _ closure: @escaping (_ barButtonItem: UIBarButtonItem) -> ()) -> Self {
        let closureContainer = ClosureContainer()
        closureContainer.closureBarButtonItem = closure
        closureContainer.owner = self
        addClosureContainer(closureContainer)
        target = closureContainer
        action = #selector(ClosureContainer.invoke)
        return self
    }
}

/*

 UISearchBar Extensions
 
*/

fileprivate class SearchBarClosureContainer: ClosureContainer, UISearchBarDelegate {
    var textDidChange: ((UISearchBar)->())?
    var didBeginEditing: ((UISearchBar)->())?
    var didEndEditing: ((UISearchBar)->())?
    var searchButtonClicked: ((UISearchBar)->())?
    var cancelButtonClicked: ((UISearchBar)->())?
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        textDidChange?(searchBar)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        didBeginEditing?(searchBar)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        didEndEditing?(searchBar)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchButtonClicked?(searchBar)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelButtonClicked?(searchBar)
    }
}

public extension UISearchBar {
    fileprivate func closureContainer() -> SearchBarClosureContainer {
        if let closureContainer = self.delegate as? SearchBarClosureContainer {
            return closureContainer
        }
        
        let closureContainer = SearchBarClosureContainer()
        closureContainer.owner = self
        self.addClosureContainer(closureContainer)
        self.delegate = closureContainer
        return closureContainer
    }
    
    @discardableResult
    func textDidChange(_ closure: @escaping(_ control: UISearchBar)->()) -> Self {
        closureContainer().textDidChange = closure
        return self
    }
    
    @discardableResult
    func didBeginEditing(_ closure: @escaping(_ control: UISearchBar)->()) -> Self {
        closureContainer().didBeginEditing = closure
        return self
    }
    
    @discardableResult
    func didEndEditing(_ closure: @escaping(_ control: UISearchBar)->()) -> Self {
        closureContainer().didEndEditing = closure
        return self
    }
    
    @discardableResult
    func searchButtonClicked(_ closure: @escaping(_ control: UISearchBar)->()) -> Self {
        closureContainer().searchButtonClicked = closure
        return self
    }
    
    @discardableResult
    func cancelButtonClicked(_ closure: @escaping(_ control: UISearchBar)->()) -> Self {
        closureContainer().cancelButtonClicked = closure
        return self
    }
}

/*

 UITextField Extensions
 
*/

fileprivate class TextFieldClosureContainer: ClosureContainer, UITextFieldDelegate {
    var shouldReturn: ((UITextField)->(Bool))?
    var shouldChangeCharacters: ((_ textField: UITextField, _ range: NSRange, _ replacementString: String)->(Bool))?
    var shouldBegin: ((UITextField)->(Bool))?
    var shouldClear: ((UITextField)->(Bool))?
    var didBegin: ((UITextField)->())?
    var didEnd: ((UITextField)->())?
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        shouldReturn?(textField) ?? false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        shouldChangeCharacters?(textField,range,string) ?? true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        shouldBegin?(textField) ?? true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        shouldClear?(textField) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBegin?(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        didEnd?(textField)
    }
}

public extension UITextField {
    fileprivate func closureContainer() -> TextFieldClosureContainer {
        if let closureContainer = self.delegate as? TextFieldClosureContainer {
            return closureContainer
        }
        
        let closureContainer = TextFieldClosureContainer()
        closureContainer.owner = self
        self.addClosureContainer(closureContainer)
        self.delegate = closureContainer
        return closureContainer
    }
    
    @discardableResult
    func shouldReturn(_ closure: @escaping(_ control: UITextField)->(Bool)) -> Self {
        closureContainer().shouldReturn = closure
        return self
    }
    
    @discardableResult
    func shouldChangeCharacters(_ closure: @escaping(_ textField: UITextField, _ range: NSRange, _ replacementString: String)->(Bool)) -> Self {
        closureContainer().shouldChangeCharacters = closure
        return self
    }
    
    @discardableResult
    func shouldClear(_ closure: @escaping(_ control: UITextField)->(Bool)) -> Self {
        closureContainer().shouldClear = closure
        return self
    }
    
    @discardableResult
    func shouldBeginEditing(_ closure: @escaping(_ control: UITextField)->(Bool)) -> Self {
        closureContainer().shouldBegin = closure
        return self
    }
    
    @discardableResult
    func didBegin(_ closure: @escaping(_ control: UITextField)->()) -> Self {
        closureContainer().didBegin = closure
        return self
    }
    
    @discardableResult
    func didEnd(_ closure: @escaping(_ control: UITextField)->()) -> Self {
        closureContainer().didEnd = closure
        return self
    }
    
}

#endif
