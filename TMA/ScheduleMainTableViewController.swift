//
//  ScheduleMainTableViewController.swift
//  TMA
//
//  Created by Arvinder Basi on 5/30/17.
//  Copyright © 2017 Abdulrahman Sahmoud. All rights reserved.
//

import UIKit
import RealmSwift

class ScheduleViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var days: UILabel!
    @IBOutlet weak var times: UILabel!
    @IBOutlet weak var dates: UILabel!
}

class ScheduleMainTableViewController: UITableViewController {

    var course: Course!
    var schedules: Results<Schedule>!
    var mode: String! // "add" or "edit"
    var scheduleToEdit: Schedule?
    
    let realm = try! Realm()
    
    func refresh() {
        schedules = self.realm.objects(Schedule.self).filter(NSPredicate(format: "course.quarter.title == %@ AND course.identifier == %@", course.quarter.title!, course.identifier!))
        
        checkCalendarAuthorizationStatus()
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
    
        // set observer for UIApplicationWillEnterForeground to refresh the app when app wakes up.
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .UIApplicationWillEnterForeground, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refresh()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.schedules.count > 0 {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .singleLine
            return 1
        }

        let rect = CGRect(x: 0,
        y: 0,
        width: self.tableView.bounds.size.width,
        height: self.tableView.bounds.size.height)
        let noDataLabel: UILabel = UILabel(frame: rect)

        noDataLabel.text = "No Schedules currently created for this course"
        noDataLabel.textColor = UIColor.gray
        noDataLabel.textAlignment = NSTextAlignment.center
        self.tableView.backgroundView = noDataLabel
        self.tableView.separatorStyle = .none

        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleMainCell", for: indexPath) as! ScheduleViewCell

        let schedule = schedules[indexPath.row]
        
        cell.title.text = schedule.title
        cell.days.text = nil
        cell.times.text = nil
        cell.dates.text = nil
        
        do {
            let decoded = try JSONSerialization.jsonObject(with: schedule.dates, options: [])
            
            if let dictFromJSON = decoded as? [String: NSObject] {
                cell.days.text = dictFromJSON["week_days"] as? String
                
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                var timesStr = ""
                
                if let begin_time = dictFromJSON["begin_time"] as? String {
                    let start_time_raw = Schedule.parseTime(from: begin_time)
                    let start = Helpers.set_time(mydate: Date(), h: start_time_raw.hour, m: start_time_raw.min)
                    timesStr += formatter.string(from: start) + " - "
                }
                
                if let end_time = dictFromJSON["end_time"] as? String {
                    let end_time_raw = Schedule.parseTime(from: end_time)
                    let end = Helpers.set_time(mydate: Date(), h: end_time_raw.hour, m: end_time_raw.min)
                    timesStr += formatter.string(from: end)
                }
                
                cell.times.text = timesStr
                
                let start_date = Helpers.get_date_from_string(strDate: dictFromJSON["start_date"]! as! String)
                let end_date = Helpers.get_date_from_string(strDate: dictFromJSON["end_date"]! as! String)
                
                formatter.dateFormat = "M/d/yy"
                cell.dates.text = "\(formatter.string(from: start_date)) to \(formatter.string(from: end_date))"
            }
        }
        catch {
            print(error.localizedDescription)
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        scheduleToEdit = schedules[indexPath.row]
        
        performSegue(withIdentifier: "editSchedule", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            
            let schedule = self.schedules[index.row]
            
            let optionMenu = UIAlertController(title: nil, message: "Schedule will be deleted forever.", preferredStyle: .actionSheet)
            
            let deleteAction = UIAlertAction(title: "Delete Event", style: .destructive, handler: {
                (alert: UIAlertAction!) -> Void in
                
                schedule.delete(from: self.realm)
            
                self.tableView.reloadData()
            })
            optionMenu.addAction(deleteAction);
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: nil)
        }//end delete
        delete.backgroundColor = .red
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            
            self.scheduleToEdit = self.schedules[index.row]
            
            self.performSegue(withIdentifier: "editSchedule", sender: nil)
        }
        edit.backgroundColor = .blue
        
        return [delete, edit]
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let scheduleAddTableViewController = segue.destination as! ScheduleAddTableViewController
        scheduleAddTableViewController.course = self.course
        
        if segue.identifier! == "addSchedule" {
            scheduleAddTableViewController.mode = "add"
            scheduleAddTableViewController.course = self.course
            scheduleAddTableViewController.previousMode = self.mode
        }
        else if segue.identifier! == "editSchedule" {
            scheduleAddTableViewController.mode = "edit"
            scheduleAddTableViewController.course = self.course
            scheduleAddTableViewController.schedule = scheduleToEdit
            scheduleAddTableViewController.previousMode = self.mode
        }
    }

}
