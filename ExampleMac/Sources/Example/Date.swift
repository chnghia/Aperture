//
//  Date.swift
//  visualizeemotion
//
//  Created by HungNV on 1/10/20.
//  Copyright © 2020 HungNV. All rights reserved.
//

import Foundation

enum AppDateFormat: String {
    
    case ddMMMyyCommahhmma          = "dd MMM yyyy, hh:mm a"
    case commahhmmaddMMMyy          = "HH:mm dd-MM-yyyy "
    case ddMMMyyyySpacehhmma        = "dd MMM yyyy hh:mm a"
    case ddMMyyyyhhmmma             = "dd-MM-yyyy hh:mm"
    case ddMMMyyyy                  = "dd MMM yyyy"
    case ddMMyyyy                   = "dd MM yyyy"
    case MMyyyy                     = "MM yyyy"
    case MMMMyyyy                   = "MMMM yyyy"
    case hhmma                      =  "hh:mm a"
    case weekdayddMMMyyy            = "EE, dd MMM yyyy"
    case HHmmddMMyyyy               = "HH:mm dd-MM-yyyy"
    case ddMMyyyyHHmmm              = "dd MM yyyy HH:mm"
    case yyyyMMddHHmm               = "yyyy-MM-dd HH:mm"
    case MMMyyyy                    = "MMM yyyy"
    case ddMMYYYY                   = "dd-MM-YYYY"
    case yyyyMMdd                   = "yyyy-MM-dd"
    case HHmm                       = "HH:mm"
    case hhmm                       = "hh:mm"
    case ha                         = "ha"
    case yyyyMMddHHmmss             = "yyyy-MM-dd HH:mm:ss"
    case ddMMYYYYTransaction        = "dd/MM/YYYY"
    case hhmmddmmyyy                = "hh:mm dd-MM-yyyy"
    
    var formatString: String {
        return self.rawValue
    }
}

extension Date {
    
    var milisecondsSince1970 : Int64 {
        return Int64((self.timeIntervalSince1970 * 1000).rounded())
    }
    
    var isInThePast: Bool {
        let now = Date()
        return self.compare(now) == ComparisonResult.orderedAscending
    }
    
    /// SwifterSwift: ISO8601 string of format (yyyy-MM-dd'T'HH:mm:ss.SSS) from date.
    ///
    ///     Date().iso8601String -> "2017-01-12T14:51:29.574Z"
    ///
    public var iso8601String: String {
        // https://github.com/justinmakaila/NSDate-ISO-8601/blob/master/NSDateISO8601.swift
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.string(from: self).appending("Z")
    }
    
    /// SwifterSwift: Create date object from ISO8601 string.
    ///
    ///     let date = Date(iso8601String: "2017-01-12T16:48:00.959Z") // "Jan 12, 2017, 7:48 PM"
    ///
    /// - Parameter iso8601String: ISO8601 string of format (yyyy-MM-dd'T'HH:mm:ss.SSSZ).
    public init?(iso8601String: String) {
        // https://github.com/justinmakaila/NSDate-ISO-8601/blob/master/NSDateISO8601.swift
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: iso8601String) {
            self = date
        } else {
            return nil
        }
    }
    
    init?(gtFormat: String, gfFormat: AppDateFormat) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = gfFormat.formatString
        if let date = dateFormatter.date(from: gtFormat) {
            self = date
        } else {
            return nil
        }
    }
    
    public var isToday: Bool {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.isDateInToday(self)
    }
    
    /**
     *  Determine if date is within the day tomorrow
     */
    public var isTomorrow: Bool {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.isDateInTomorrow(self)
    }
    
    /**
     *  Determine if date is within yesterday
     */
    public var isYesterday: Bool {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.isDateInYesterday(self)
    }
    
    /**
     *  Determine if date is in a weekend
     */
    public var isWeekend: Bool {
        if weekday == 7 || weekday == 1 {
            return true
        }
        return false
    }
    
    // MARK: - Components
    
    /**
     *  Convenience getter for the date's `era` component
     */
    public var era: Int {
        return component(.era)
    }
    
    /**
     *  Convenience getter for the date's `year` component
     */
    public var year: Int {
        return component(.year)
    }
    
    /**
     *  Convenience getter for the date's `month` component
     */
    public var month: Int {
        return component(.month)
    }
    
    /**
     *  Convenience getter for the date's `week` component
     */
    public var week: Int {
        return component(.weekday)
    }
    
    /**
     *  Convenience getter for the date's `day` component
     */
    public var day: Int {
        return component(.day)
    }
    
    /**
     *  Convenience getter for the date's `hour` component
     */
    public var hour: Int {
        return component(.hour)
    }
    
    /**
     *  Convenience getter for the date's `minute` component
     */
    public var minute: Int {
        return component(.minute)
    }
    
    /**
     *  Convenience getter for the date's `second` component
     */
    public var second: Int {
        return component(.second)
    }
    
    /**
     *  Convenience getter for the date's `weekday` component
     */
    public var weekday: Int {
        return component(.weekday)
    }
    
    /**
     *  Convenience getter for the date's `weekdayOrdinal` component
     */
    public var weekdayOrdinal: Int {
        return component(.weekdayOrdinal)
    }
    
    /**
     *  Convenience getter for the date's `quarter` component
     */
    public var quarter: Int {
        return component(.quarter)
    }
    
    /**
     *  Convenience getter for the date's `weekOfYear` component
     */
    public var weekOfMonth: Int {
        return component(.weekOfMonth)
    }
    
    /**
     *  Convenience getter for the date's `weekOfYear` component
     */
    public var weekOfYear: Int {
        return component(.weekOfYear)
    }
    
    /**
     *  Convenience getter for the date's `yearForWeekOfYear` component
     */
    public var yearForWeekOfYear: Int {
        return component(.yearForWeekOfYear)
    }
    
    //first date in month
    
    public var firstDateInMonth : Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year,.month], from: self))!
    }
    
    /**
     *  Convenience getter for the date's `daysInMonth` component
     */
    public var daysInMonth: Int {
        let calendar = Calendar.autoupdatingCurrent
        let days = calendar.range(of: .day, in: .month, for: self)
        return days!.count
    }
    
    /// get element in date with component
    public func component(_ component: Calendar.Component) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.component(component, from: self)
    }
    
    /// convert Date to String with date format String
    func toString(formatString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        return dateFormatter.string(from: self)
    }
    
    /// convert Date to String with date format
    func toString(dateFormat: AppDateFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat.formatString
        return dateFormatter.string(from: self)
    }
    
    /// convert time to type UTC
    func toStringUTC(dateFormat: AppDateFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat.formatString
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: self)
    }
    
    // constructor convert string to date
    public init?(yyyyMMddHHmmss: String) {
        // https://github.com/justinmakaila/NSDate-ISO-8601/blob/master/NSDateISO8601.swift
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: yyyyMMddHHmmss) {
            self = date
        } else {
            return nil
        }
    }
}
