//
//  Helpers.swift
//  TMA
//
//  Created by Abdulrahman Sahmoud on 2/5/17.
//  Copyright © 2017 Abdulrahman Sahmoud. All rights reserved.
//

import UIKit
import Foundation
import RealmSwift
import Alamofire

let colorMappings: [String: UIColor] = ["None": UIColor.clear, "Yellow": UIColor.yellow, "Red": UIColor.red, "Green": UIColor.green, "Blue": UIColor.blue, "Purple": UIColor.purple, "Cyan": UIColor.cyan, "Brown": UIColor.brown, "Black": UIColor.black]

class Helpers {
    static let realm = try! Realm()
    
    static func DB_insert(obj: Object){
        try! self.realm.write {
            self.realm.add(obj)
        }
    }
    
    static func add_duration_studied(for course: Course, in quarter: Quarter) -> Float {
        var sum: Float = 0.0
        let events = self.realm.objects(Event.self).filter("course.title = '\(course.title!)' AND course.quarter.title = '\(quarter.title!)'")
        for event in events {
            sum += event.durationStudied
        }
        return sum
    }
    
    static func add_duration(events: Results<Event>) -> Float{
        var sum: Float = 0.0
        for x in events {
            sum += x.duration
        }
        return sum
    }
    
    static func add_duration_studied(events: Results<Event>) -> Float{
        var sum: Float = 0.0
        for x in events {
            sum += x.durationStudied
        }
        return sum
    }
    
    static func get_date_from_string(strDate: String) -> Date {
        let formatter = DateFormatter()
        
        let a = strDate.components(separatedBy: " ")
        let b = a[0]+" "+a[1]+" "+a[2]
        
        formatter.locale = Locale(identifier: "US_en")
        formatter.dateFormat = "MMM, dd yyyy"
        
        let x = formatter.date(from: b)
        return x!
    }
    
    static func set_time(mydate: Date, h: Int, m: Int) -> Date{
        let gregorian = Calendar(identifier: .gregorian)
        var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: mydate)
        components.hour = h
        components.minute = m
        components.second = 0
        
        return gregorian.date(from: components)!
    }
    
    static func getLogAlert(event: Event, realm: Realm) -> UIAlertController {
        let alert = UIAlertController(title: "Enter Time", message: "How much time (in hours and minutes) did you spend studying?", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
            textField.placeholder = "Hours"
            //textField.text = "\(floor(event.duration))"
        }
        
        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
            textField.placeholder = "Minutes"
            //textField.text = "\((event.duration - floor(event.duration)) * 60)"
        }
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
            let hoursField = alert!.textFields![0]
            let minsField = alert!.textFields![1]
            
            var durationStudied: Float = 0.0
            
            if hoursField.text != "" {
                durationStudied += (Float(hoursField.text!)!)
            }
            
            if minsField.text != "" {
                durationStudied += (Float(minsField.text!)!) / 60
            }
            
            try! self.realm.write {
                event.durationStudied = durationStudied
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Skip", style: .cancel, handler: nil))
        return alert
    }
    
    static func export_data_to_server(responseHandler: @escaping (DataResponse<Any>) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        
        let allQuarters = realm.objects(Quarter.self)
        var quartersJSON = [Dictionary<String, Any>]()
        for quarter in allQuarters {
            var quarterJSON = quarter.toDictionary() as! Dictionary<String, Any>
            quarterJSON["startDate"] = formatter.string(from: quarterJSON["startDate"] as! Date)
            quarterJSON["endDate"] = formatter.string(from: quarterJSON["endDate"] as! Date)
            var coursesJSON = [[String: Any]]()
            
            let courses = realm.objects(Course.self).filter("quarter.title = '\(quarter.title!)'")
            for course in courses {
                var courseJSON = course.toDictionary() as! Dictionary<String, Any>
                courseJSON.removeValue(forKey: "quarter")
                var eventsJSON = [[String: Any]]()
                
                let events = realm.objects(Event.self).filter("course.title = '\(course.title!)'")
                for event in events {
                    var eventJSON = event.toDictionary() as! Dictionary<String, Any>
                    eventJSON["date"] = formatter.string(from: eventJSON["date"] as! Date)
                    eventJSON["endDate"] = formatter.string(from: eventJSON["endDate"] as! Date)
                    eventJSON.removeValue(forKey: "course")
                    eventJSON.removeValue(forKey: "calEventID")
                    eventJSON.removeValue(forKey: "reminderDate")
                    eventJSON.removeValue(forKey: "reminderID")
                    eventsJSON.append(eventJSON)
                }
                
                courseJSON["events"] = eventsJSON
                coursesJSON.append(courseJSON)
            }
            
            quarterJSON["courses"] = coursesJSON
            quartersJSON.append(quarterJSON)
        }
        
        let parameters: Parameters = ["quarters": quartersJSON]
        
        Alamofire.request("http://192.241.206.161/chart?UID=\(UIDevice.init().identifierForVendor!)", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON (completionHandler: responseHandler)
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    func dayOfTheWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: self)
    }
    
    func dayOfTheMonth() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        return dateFormatter.string(from: self)
    }
    
    static func getEndDate(fromStart start: Date, withDuration duration: Float) -> Date{
        var components = DateComponents()
        components.setValue(Int(duration), for: .hour)
        components.setValue(Int(round(60 * (duration - floor(duration)))), for: .minute)
        return Calendar.current.date(byAdding: components, to: start)!
    }
    
    static func getDifference(initial start: Date, final end: Date) -> Float {
        let interval = end.timeIntervalSince(start) // In seconds. Note: TimeInterval = double
        
        // Convert seconds to hours.
        return (Float(interval / (60.0 * 60.0)))
    }
    
    func daysBetween(date: Date) -> Int {
        return Date.daysBetween(start: self, end: date)
    }
    
    static func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: start)
        let date2 = calendar.startOfDay(for: end)
        
        let a = calendar.dateComponents([.day], from: date1, to: date2)
        return a.value(for: .day)!
    }
}

extension UIViewController {
    // Makes it so any keyboard/numpad currently active disappears when user clicks away.
    func hideKeyboardWhenTapped() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func setGradientBackground(colorTop: UIColor, colorBottom: UIColor) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop.cgColor, colorBottom.cgColor]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = view.bounds
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setTheme(theme: Theme) {
        self.navigationController!.navigationBar.barTintColor = theme.barColor
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: theme.tintColor]
        self.navigationController!.navigationBar.tintColor = theme.tintColor
        
        self.tabBarController!.tabBar.barTintColor = theme.barColor
        self.tabBarController!.tabBar.tintColor = theme.tintColor
    }
}

extension Object {
    func toDictionary() -> NSDictionary {
        let properties = self.objectSchema.properties.map { $0.name }
        let dictionary = self.dictionaryWithValues(forKeys: properties)
        let mutabledic = NSMutableDictionary()
        mutabledic.setValuesForKeys(dictionary)
        
        for prop in self.objectSchema.properties as [Property]! {
            // find lists
            if let nestedObject = self[prop.name] as? Object {
                mutabledic.setValue(nestedObject.toDictionary(), forKey: prop.name)
            } else if let nestedListObject = self[prop.name] as? ListBase {
                var objects = [AnyObject]()
                for index in 0..<nestedListObject._rlmArray.count  {
                    let object = nestedListObject._rlmArray[index] as AnyObject
                    objects.append(object.toDictionary())
                }
                mutabledic.setObject(objects, forKey: prop.name as NSCopying)
            }
        }
        return mutabledic
    }
}
