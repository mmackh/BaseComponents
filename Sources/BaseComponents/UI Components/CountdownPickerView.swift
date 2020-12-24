//
//  CountdownPickerView.swift
//  BaseComponents
//
//  Created by mmackh on 07.06.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#if os(iOS)

import UIKit

/**
 Display a countdown picker with seconds that is very close to the native iOS Timer app
 
 All labels will be translated automatically depending on the phone's locale. A maximum width prevents this view from overflowing.
 
 # Best Practices
 1. If required, set `countDownDuration` only after `isEndless` has been set
 
 # Code Example
 ```
 let datePicker = CountdownPickerView()
 datePicker.isEndless = true
 datePicker.countDownDuration = TimeInterval(3 * 60 * 60 + 2 * 60 + 1)
 view.addSubview(datePicker)
 ```
 */
public class CountdownPickerView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {
    /**
     Declares whether the picker wraps around, i.e. above 0, there's 23
     
     Is not truly endless, since the `CountdownPickerView` is based on `UIPickerView`, which does not support infinite scrolling by default. However, it'll provide a solution that is decent enough that 99.999% of users will not reach the end of the picker.
     */
    public var isEndless: Bool = false {
        didSet {
            loopMultiplier = isEndless ? 1000 : 1
            pickerView.reloadAllComponents()
            
            if loopMultiplier > 1 {
                for i in 0..<3 {
                    let targetRow: Int = value(for: i) * loopMultiplier / 2
                    pickerView.selectRow(targetRow, inComponent: i, animated: false)
                }
            }
        }
    }
    
    /**
     Current count down duration in seconds using `TimeInterval` that has been set programatically or chosen by the user
     
     Default is 0.0. limit is 23:59 (86,399 seconds). Should be set after `isEndless`, since `isEndless` modifies the position of the rows as well.
     */
    public var countDownDuration: TimeInterval {
        get {
            return countDownDurationInternal
        }
        set {
            countDownDurationInternal = newValue
            let secondsTotal = Int(newValue)
            
            let hours: Int = secondsTotal / 3600
            let minutes: Int = (secondsTotal % 3600) / 60
            let seconds: Int = secondsTotal % 60
            if isEndless {
                pickerView.selectRow((24 * loopMultiplier / 2) + hours, inComponent: 0, animated: false)
                pickerView.selectRow(60 * loopMultiplier / 2 + minutes, inComponent: 1, animated: false)
                pickerView.selectRow(60 * loopMultiplier / 2 + seconds, inComponent: 2, animated: false)
            } else {
                pickerView.selectRow(hours, inComponent: 0, animated: false)
                pickerView.selectRow(minutes, inComponent: 1, animated: false)
                pickerView.selectRow(seconds, inComponent: 2, animated: false)
            }
        }
    }
    
    private var countDownDurationInternal: TimeInterval = 0
    private var loopMultiplier: Int = 1
    private let pickerView: UIPickerView = UIPickerView()
    private let containerView: UIView = UIView()
    
    private enum Column: Int {
        case hours = 0
        case minutes
        case seconds
        case hour
    }
    
    static var hourPluralString: String = title(for: .hours)
    static var hourString: String = title(for: .hour)
    static var minuteString: String = title(for: .minutes)
    static var secondString: String = title(for: .seconds)
    
    let hourLabel: UILabel = timerLabel(with: hourPluralString)
    let minuteLabel: UILabel = timerLabel(with: minuteString)
    let secondsLabel: UILabel = timerLabel(with: secondString)
    
    init() {
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        pickerView.dataSource = self
        containerView.addSubview(pickerView)
        
        containerView.addSubview(hourLabel)
        containerView.addSubview(minuteLabel)
        containerView.addSubview(secondsLabel)
    }
    
    private static func title(for column: Column, plural: Bool = false) -> String {
        let measurementFormatter: MeasurementFormatter = {
            let measurementFormatter = MeasurementFormatter()
            measurementFormatter.locale = Locale.current
            measurementFormatter.unitOptions = .providedUnit
            measurementFormatter.unitStyle = (column == .hours) ? .long : .short
            return measurementFormatter
        }()
        
        switch column {
        case .hour:
            return measurementFormatter.string(from: UnitDuration.hours)
        case .minutes:
            return measurementFormatter.string(from: UnitDuration.minutes)
        case .seconds:
            return measurementFormatter.string(from: UnitDuration.seconds)
        case .hours:
            return String(measurementFormatter.string(from: Measurement(value: 2, unit: UnitDuration.hours)).split(separator: " ").last ?? "hours")
        }
    }
    
    static func timerLabel(with title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }
    
    func value(for component: Int) -> Int {
        component == 0 ? 24 : 60
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        3
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        value(for: component) * loopMultiplier
    }
    
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        floor(pickerView.bounds.size.width / 3) - (component == 2 ? 5 : 5)
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel = UILabel("")
        label.font = .systemFont(ofSize: 22, weight: .regular)
        label.textAlignment = .right
        label.text = String(row % value(for: component))
        
        let width = floor(pickerView.bounds.size.width / 3) - 5
        label.frame = .init(x: 20, y: 0, width: 30, height: 30)
        let containerView: UIView = .init(frame: .init(x: 0, y: 0, width: width, height: 30))
        containerView.addSubview(label)
        return containerView
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hours: Int = pickerView.selectedRow(inComponent: Column.hours.rawValue)
        
        hourLabel.text = hours == 1 ? CountdownPickerView.hourString : CountdownPickerView.hourPluralString
        
        let hoursSeconds: Int = hours % 24 * 60 * 60
        let minutesSeconds: Int = pickerView.selectedRow(inComponent: Column.minutes.rawValue) % 60 * 60
        let seconds: Int = pickerView.selectedRow(inComponent: Column.seconds.rawValue) % 60
        
        countDownDurationInternal = TimeInterval(hoursSeconds + minutesSeconds + seconds)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let containerWidth: CGFloat = min(bounds.size.width, 480)
        containerView.frame = .init(x: (bounds.size.width - containerWidth) / 2, y: 0, width: containerWidth, height: bounds.size.height)
        
        pickerView.frame = containerView.bounds
        
        let height: CGFloat = 30
        let y: CGFloat = bounds.size.height / 2 - height / 2
        let offset: CGFloat = 59
        hourLabel.frame = .init(x: (containerView.bounds.size.width / 3) * 0 + offset, y: y, width: 50, height: height)
        minuteLabel.frame = .init(x: (containerView.bounds.size.width / 3) * 1 + offset, y: y, width: 50, height: height)
        secondsLabel.frame = .init(x: (containerView.bounds.size.width / 3) * 2 + offset, y: y, width: 50, height: height)
    }
}

#endif
