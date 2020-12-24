//
//  TimeKeep.swift
//  BaseComponents
//
//  Created by mmackh on 13.07.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public enum TimeUnit {
    case second(_ value: Int)
    case minute(_ value: Int)
    case hour(_ value: Int)
    case day(_ value: Int)
    case month(_ value: Int)
    case year(_ value: Int)
}

public extension Date {
    static var calendar: Calendar = {
        Calendar.current
    }()
    static var formatter: DateFormatter = {
        let dateFormatter = DateFormatter.init()
        dateFormatter.locale = .autoupdatingCurrent
        return dateFormatter
    }()
    
    @available(iOS 13.0, watchOS 6.0, *)
    static var relativeFormatter: RelativeDateTimeFormatter = {
        RelativeDateTimeFormatter()
    }()
    
    static func dates(between startDate: Date, until endDate: Date) -> [Date] {
        var dates: [Date] = []
        if let days = Date.difference(between: startDate, until: endDate, components: [.day]).day {
            for n in 0...days {
                dates.append(startDate.add(.day(n)))
            }
        }
        return dates
    }
    
    func dates(until date: Date) -> [Date] {
        Date.dates(between: self, until: date)
    }
    
    static func difference(between startDate: Date, until endDate: Date, components: Set<Calendar.Component>) -> DateComponents {
        let startDateCleaned = calendar.startOfDay(for: startDate)
        let endDateCleaned = calendar.startOfDay(for: endDate)
        return calendar.dateComponents(components, from: startDateCleaned, to: endDateCleaned)
    }
    
    func distance(in component: Calendar.Component, to date: Date) -> Int {
        if component == .second {
            let difference = Date.calendar.dateComponents([.second], from: self, to: date)
            if let value = difference.second {
                return value
            }
        }
        if component == .minute {
            let difference = Date.calendar.dateComponents([.minute], from: self, to: date)
            if let value = difference.minute {
                return value
            }
        }
        if component == .hour {
            let difference = Date.calendar.dateComponents([.hour], from: self, to: date)
            if let value = difference.hour {
                return value
            }
        }
        if component == .day {
            let difference = Date.difference(between: self, until: date, components: [.day])
            if let value = difference.day {
                return value
            }
        }
        if component == .month {
            let difference = Date.difference(between: self, until: date, components: [.month])
            if let value = difference.month {
                return value
            }
        }
        if component == .year {
            let difference = Date.difference(between: self, until: date, components: [.year])
            if let value = difference.year {
                return value
            }
        }
        return 0
    }
    
    func add(_ timeUnit: TimeUnit) -> Date {
        if case let .second(value) = timeUnit { return addComponent(.second, value: value) }
        if case let .minute(value) = timeUnit { return addComponent(.minute, value: value) }
        if case let .hour(value) = timeUnit { return addComponent(.hour, value: value) }
        if case let .day(value) = timeUnit { return addComponent(.day, value: value) }
        if case let .month(value) = timeUnit { return addComponent(.month, value: value) }
        if case let .year(value) = timeUnit { return addComponent(.year, value: value) }
        return self
    }
    
    func remove(_ timeUnit: TimeUnit) -> Date {
        if case let .second(value) = timeUnit { return addComponent(.second, value: value * -1) }
        if case let .minute(value) = timeUnit { return addComponent(.minute, value: value * -1) }
        if case let .hour(value) = timeUnit { return addComponent(.hour, value: value * -1) }
        if case let .day(value) = timeUnit { return addComponent(.day, value: value * -1) }
        if case let .month(value) = timeUnit { return addComponent(.month, value: value * -1) }
        if case let .year(value) = timeUnit { return addComponent(.year, value: value * -1) }
        return self
    }
    
    func addComponent(_ component: Calendar.Component, value: Int) -> Date {
        if let date = Date.calendar.date(byAdding: component, value: value, to: self) {
            return date
        }
        return self
    }
    
    func startOf(_ component: Calendar.Component) -> Date {
        var components: Set<Calendar.Component> = []
        if component == .second {
            components = [.second,.minute,.hour,.day,.month, .year]
        }
        if component == .minute {
            components = [.minute,.hour,.day,.month, .year]
        }
        if component == .hour {
            components = [.hour,.day,.month, .year]
        }
        if component == .day {
            components = [.day,.month, .year]
        }
        if component == .month {
            components = [.month, .year]
        }
        if component == .year {
            components = [.year]
        }
        
        if let date = Date.calendar.date(from: Date.calendar.dateComponents(components, from: self)) {
            return date
        }
        return self
    }
    
    func format() {
        let formatter = Date.formatter
        formatter.timeStyle = .short
        formatter.dateStyle = .short
    }
    
    func format(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = Date.formatter
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    func format(string: String) -> String {
        let formatter = Date.formatter
        formatter.dateFormat = string
        return formatter.string(from: self)
    }
    
    @available(iOS 13.0, watchOS 6.0, *)
    func format(relative to: Date) -> String {
        Date.relativeFormatter.localizedString(for: self, relativeTo: to)
    }
}
