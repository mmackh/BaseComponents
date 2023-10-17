import UIKit
import PlaygroundSupport
import BaseComponents

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.build {
            Equal {
                let textField = UITextField(placeholder: "Test")
                textField.transform = .init(scaleX: <#T##CGFloat#>, y: <#T##CGFloat#>)
                textField.addAction(for: .editingChanged) { textField in
                    print("value changed", textField)
                }
                textField.shouldReturn { control in
                    print("should return")
                    return true
                }
                return textField
            } insets: {
                .init(horizontal: 15, vertical: 15)
            }
        }
    }
}

// let liveViewController = ScrollingViewController().embedInNavigationController()
let liveViewController = ViewController().embedInNavigationController()
liveViewController.view.frame = .init(x: 0, y: 0, width: 320, height: 480)
PlaygroundPage.current.liveView = liveViewController
