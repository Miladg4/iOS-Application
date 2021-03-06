//
//  Event.swift
//  TMA
//
//  Created by Abdulrahman Sahmoud on 2/5/17.
//  Copyright © 2017 Abdulrahman Sahmoud. All rights reserved.
//

import Foundation
import RealmSwift
import UserNotifications

class Event: Item {
    dynamic var checked: Bool = false
    dynamic var reminderID: String = UUID().uuidString
    dynamic var reminderDate: Date? = nil
    dynamic var calEventID: String? = nil
    dynamic var durationStudied: Float = 0.0 //hours
    dynamic var schedule: Schedule? // If the event is related to a particular schedule.
    
    func delete(from realm: Realm) {
        
        // Remove any pending notifications for the event.
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.reminderID])
        
        if let id = self.calEventID {
            deleteEventFromCalendar(withID: id)
        }
        
        try! realm.write {
            realm.delete(self)
        }
    }
}
