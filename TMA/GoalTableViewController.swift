//
//  GoalTableViewController.swift
//  TMA
//
//  Created by Milad Ghoreishi on 4/10/17.
//  Copyright © 2017 Abdulrahman Sahmoud. All rights reserved.
//

import UIKit
import RealmSwift

class GoalViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var deadline: UILabel!
    @IBOutlet weak var remaining: UILabel!
}

class GoalTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
        let realm = try! Realm()
        
    
        @IBOutlet weak var tableView: UITableView!
    
        var currentQuarter: Quarter!
        var goalToEdit: Goal!
        var goals: Results<Goal>!
        var courses: Results<Course>!
        
        @IBAction func add(_ sender: Any) {
            self.performSegue(withIdentifier: "addGoal", sender: nil)
        }
    
    
        func initializeGoalsAndCourses() {
            let currentQuarters = self.realm.objects(Quarter.self).filter("current = true")
            if currentQuarters.count != 1 {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                let alert = UIAlertController(title: "Current Quarter Error", message: "You must have one current quarter.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                currentQuarter = currentQuarters[0]
                self.courses = self.realm.objects(Course.self).filter("quarter.title = '\(self.currentQuarter.title!)'")
                
                if self.courses.count == 0 {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    let alert = UIAlertController(title: "No Courses Error", message: "You must have at least one course in the current quarter.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    self.goals = self.realm.objects(Goal.self).filter("course.quarter.title = '\(self.currentQuarter.title!)'")
                }
                
            }
        }
    
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            initializeGoalsAndCourses()
            self.tableView.reloadData()
            
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            initializeGoalsAndCourses()
            self.tableView.reloadData()
            
            //self.tableView.tableFooterView = UIView()
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
        // MARK: - Table view data source
        
    
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            
            let courseForSection = self.courses[section]
            return courseForSection.name!
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            if self.goals.count > 0 {
                self.tableView.backgroundView = nil
                self.tableView.separatorStyle = .singleLine
                
                return self.goals.count
            }
            
            else {
                let image = UIImage(named: "bar-chart")!
                let topMessage = "Goals"
                let bottomMessage = "You haven't created any goals. All your goals will show up here."
                
                self.tableView.backgroundView = EmptyBackgroundView(image: image, top: topMessage, bottom: bottomMessage)
                self.tableView.separatorStyle = .none
                
                return 0
            }
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let courseForSection = self.courses[section]
            return self.goals.filter("course.name = '\(courseForSection.name!)'").count
        }
    
        
        func getGoalAndCourseAtIndexPath(indexPath: IndexPath) -> (Goal, Course) {
            let courseForSection = self.courses[indexPath.section]
            let goalsForSection = self.goals.filter("course.name = '\(courseForSection.name!)'")
            let goal = goalsForSection[indexPath.row]
            
            return (goal, courseForSection)
        }
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GoalCell", for: indexPath) as! GoalViewCell
            
            let (goal, _) = getGoalAndCourseAtIndexPath(indexPath: indexPath)
            
            cell.title?.text = goal.title
            cell.type?.text = "\(eventType[goal.type]) Goal"
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "US_en")
            formatter.dateFormat = "M/d/yy"
            
            cell.deadline?.text = formatter.string(from: goal.deadline)
            
            cell.remaining?.text = "\(goal.duration) Hours Remaining"
            
            return cell
        }
        
        func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
            
            
            
            let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
                
                let (goal, _) = self.getGoalAndCourseAtIndexPath(indexPath: index)
                
                let optionMenu = UIAlertController(title: nil, message: "\"\(goal.title!)\" and all associated events will be deleted forever.", preferredStyle: .actionSheet)
                //delete goals, events, logs
                
                let deleteAction = UIAlertAction(title: "Delete Goal", style: .destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    
                    try! self.realm.write {
                        let logsToDelete = self.realm.objects(Log.self).filter("goal.title = '\(goal.title!)'")
                        self.realm.delete(logsToDelete)
                        
                        let eventsToDelete = self.realm.objects(Event.self).filter("goal.title = '\(goal.title!)'")
                        self.realm.delete(eventsToDelete)
                        
                        self.realm.delete(goal)
                    }
                    self.tableView.reloadData()
                })
                optionMenu.addAction(deleteAction);
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                    
                })
                optionMenu.addAction(cancelAction)
                
                self.present(optionMenu, animated: true, completion: nil)
            }//end delete
            delete.backgroundColor = .red
            
            let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
                let (goal, _) = self.getGoalAndCourseAtIndexPath(indexPath: index)
                
                self.goalToEdit = goal
                
                self.performSegue(withIdentifier: "editGoal", sender: nil)
            }
            edit.backgroundColor = .blue
            
            return [delete, edit]
        }
        
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
    
    
        // MARK: - Navigation
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
            if segue.identifier! == "showGoal" {
                
                let plannerViewController = segue.destination as! PlannerViewController
                
                let selectedIndexPath = tableView.indexPathForSelectedRow
                
                let (goal, _) = self.getGoalAndCourseAtIndexPath(indexPath: selectedIndexPath!)
                
            }
            else {

                let navigation: UINavigationController = segue.destination as! UINavigationController
                
               var goalAddViewController = GoalAddTableViewController.init()
                
                goalAddViewController = navigation.viewControllers[0] as! GoalAddTableViewController
                
                if segue.identifier! == "addGoal" {
                    goalAddViewController.operation = "add"
                }
                else if segue.identifier! == "editGoal" {
                    goalAddViewController.operation = "edit"
                    goalAddViewController.goal = goalToEdit!
                }
            }
        }
}