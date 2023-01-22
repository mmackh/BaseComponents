//
//  Profiler.swift
//  BaseComponents
//
//  Created by mmackh on 07.11.22.
//  Copyright © 2022 Maximilian Mackh. All rights reserved.
//

import Foundation

open class Profiler: CustomDebugStringConvertible {
    public struct Measurement {
        let label: String
        let initTimeInterval: TimeInterval
        let duration: TimeInterval
    }
    
    let label: String
    let initTimeInterval: TimeInterval
    var elapsed: TimeInterval {
        Profiler.uptime() - initTimeInterval
    }
    
    public var significantFigures: Int = 4
    
    private var lastMeasurementTimeInterval: TimeInterval = 0
    private var measurements: [Measurement] = []
    
    private let file: String
    private let function: String
    private let line: Int
    
    public init(label: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.initTimeInterval = Profiler.uptime()
        self.label = label
        
        self.file = file
        self.function = function
        self.line = line
    }
    
    @discardableResult
    public init(label: String, file: String = #fileID, function: String = #function, line: Int = #line, _ profile: ()->()) {
        self.initTimeInterval = Profiler.uptime()
        self.label = label
        
        self.file = file
        self.function = function
        self.line = line
        
        profile()
        
        print(self)
    }
    
    static func uptime() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
    
    public func measure(_ measurementLabel: String) {
        let relativeTimeInterval: TimeInterval = lastMeasurementTimeInterval == 0 ? initTimeInterval : lastMeasurementTimeInterval
        
        let uptime = Profiler.uptime()
        lastMeasurementTimeInterval = uptime
        
        let measurement: Measurement = .init(label: measurementLabel, initTimeInterval: uptime, duration: uptime - relativeTimeInterval)
        measurements.append(measurement)
    }
    
    public func measure(_ measurementLabel: String, _ codeBlock: ()->()) {
        codeBlock()
        measure(measurementLabel)
    }
    
    public var debugDescription: String {
        let elapsed: TimeInterval = self.elapsed
        var measurementDebugDescription: String = ""
        for (idx, measurement) in measurements.sorted(by: { $0.duration > $1.duration }).enumerated() {
            if idx == 0 {
                measurementDebugDescription += "   Measurements: \n"
            }
            let measurementFormat = "      -> %@ | %.0\(significantFigures)f | %.01f%%\n"
            measurementDebugDescription += String(format: measurementFormat, measurement.label, measurement.duration, (measurement.duration / elapsed) * 100)
        }
        
        let debugFormat = "[Profiler] - %@\n   %@:%i | %@ \n%@   Total Elapsed: %.0\(significantFigures)fs"
        return String(format: debugFormat, label, file.lastPathComponent, line, function, measurementDebugDescription, elapsed)
    }
}
