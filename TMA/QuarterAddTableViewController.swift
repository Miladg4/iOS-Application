//
//  QuarterAddTableViewController.swift
//  TMA
//
//  Created by Arvinder Basi on 3/30/17.
//  Copyright © 2017 Abdulrahman Sahmoud. All rights reserved.
//

import UIKit
import RealmSwift
import FSCalendar

class QuarterAddTableViewController: UITableViewController, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, UITextFieldDelegate {

    let realm = try! Realm()
    
    var operation: String = ""
    var quarter: Quarter?
    var dateFormatter: DateFormatter = DateFormatter()
    
    let titlePath = IndexPath(row: 0, section: 0)
    let startPath = IndexPath(row: 0, section: 1)
    let startPickerPath = IndexPath(row: 1, section: 1)
    let endPath = IndexPath(row: 2, section: 1)
    let endPickerPath = IndexPath(row: 3, section: 1)
    
    @IBOutlet weak var quarterTitle: UITextField!
    @IBOutlet weak var currentSwitch: UISwitch!
    
    @IBOutlet weak var startDate: UITextField!
    @IBOutlet weak var startDatePicker: FSCalendar!
    
    @IBOutlet weak var endDate: UITextField!
    @IBOutlet weak var endDatePicker: FSCalendar!
    
    @IBOutlet weak var pageTitle: UINavigationItem!
    
    @IBAction func quarterTitleChanged(_ sender: Any) {
        if ((quarterTitle.text?.isEmpty)! == false) {
            changeTextFieldToWhite(indexPath: titlePath)
        }
    }
    
    private func toggleStartDatePicker() {
        startDatePicker.isHidden = !startDatePicker.isHidden
        
        if !startDatePicker.isHidden && !endDatePicker.isHidden {
            endDatePicker.isHidden = true
        }
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    private func toggleEndDatePicker() {
        endDatePicker.isHidden = !endDatePicker.isHidden
        
        if !endDatePicker.isHidden && !startDatePicker.isHidden {
            startDatePicker.isHidden = true
        }
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }

    // Checks if the quarter title is a duplicate. Returns false if it is.
    private func isDuplicate() -> Bool {
        // Check to make sure that this course has a different title than all others.
        
        let quarters = self.realm.objects(Quarter.self).filter(NSPredicate(format: "title == %@", quarterTitle.text!))
        if quarters.count != 0 {
            let alert = UIAlertController(title: "Error", message: "Quarter with this title already Exists", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return true
        }
        return false
    }
    
    @IBAction func save(_ sender: Any) {
        
        if (self.quarterTitle.text?.isEmpty)! {
            
            let alert = UIAlertController(title: "Alert", message: "Missing Required Information.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            if (self.quarterTitle.text?.isEmpty)! {
                changeTextFieldToRed(indexPath: titlePath)
            }
        }
        else {
            
            var start: Date
            var end: Date
            
            if startDate.text != "" {
                start = dateFormatter.date(from: startDate.text!)!
            }
            else {
                start = Date()
            }
            
            if endDate.text != "" {
                end = dateFormatter.date(from: endDate.text!)!
            }
            else {
                var components = DateComponents()
                components.setValue(2, for: .month)
                end = Calendar.current.date(byAdding: components, to: start)!
            }
            
            if(start >= end) {
                let alert = UIAlertController(title: "Alert", message: "Invalid Quarter dates. Ensure that the start date is before the end date.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                
                changeTextFieldToRed(indexPath: startPath)
                changeTextFieldToRed(indexPath: endPath)
                
                return
            }
            
            if operation == "add" {
                if isDuplicate() {
                    return
                }
                
                self.quarter = Quarter()
                quarter!.title = quarterTitle.text!
                
                quarter!.startDate = start
     
                quarter!.endDate = end
                
                quarter!.current = currentSwitch.isOn
                
                // Make sure no other quarter is set to current.
                if(currentSwitch.isOn) {
                    let currentQuarters = self.realm.objects(Quarter.self).filter("current = true")
                    
                    // Another 'current' quarter exists.
                    if(currentQuarters.count != 0) {
                        let alert = UIAlertController(title: "Current Quarter Error", message: "You can only have one current quarter.", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                }

                Helpers.DB_insert(obj: quarter!)
            }
            else if operation == "edit" {
                try! self.realm.write {
                    
                    if quarter!.title != quarterTitle.text!
                    {
                        if isDuplicate() {
                            return
                        }
                        else {
                            quarter!.title = quarterTitle.text!
                        }
                    }
                    
                    quarter!.startDate = start
                    quarter!.endDate = end
                    
                    // Make sure no other quarter is set to current.
                    if(currentSwitch.isOn) {
                        let quarters = self.realm.objects(Quarter.self)
                        
                        for quarter in quarters {
                            quarter.current = false
                        }
                    }
                    
                    quarter!.current = currentSwitch.isOn
                }
            }
            
            self.dismissKeyboard()
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.locale = Locale(identifier: "US_en")
        dateFormatter.dateFormat = "M/d/yy"
        
        self.quarterTitle.delegate = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.startDatePicker.delegate = self
        self.startDatePicker.dataSource = self
        self.startDatePicker.isHidden = true
        self.startDatePicker.today = nil
        
        self.endDatePicker.delegate = self
        self.endDatePicker.dataSource = self
        self.endDatePicker.isHidden = true
        self.endDatePicker.today = nil
        
        self.currentSwitch.isOn = false
        
        self.tableView.tableFooterView = UIView()
        
        if self.operation == "edit" {
            self.pageTitle.title = self.quarter!.title
            self.quarterTitle.text = self.quarter!.title
            self.currentSwitch.isOn = self.quarter!.current
            
            self.startDate.text = dateFormatter.string(from: self.quarter!.startDate)
            self.endDate.text = dateFormatter.string(from: self.quarter!.endDate)
        }
        
        self.hideKeyboardWhenTapped()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /******************************* Table View Functions *******************************/

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == startPath {
            toggleStartDatePicker()
        }
        else if indexPath == endPath {
            toggleEndDatePicker()
        }
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if startDatePicker.isHidden && indexPath == startPickerPath {
            return 0
        }
        else if endDatePicker.isHidden && indexPath == endPickerPath {
            return 0
        }
        else {
            return super.tableView(self.tableView, heightForRowAt: indexPath)
        }
    }

    /******************************* Text Field Functions *******************************/
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /******************************* Calendar Functions *******************************/
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition){
        if calendar == startDatePicker {
            self.startDate.text = dateFormatter.string(from: date)
            changeTextFieldToWhite(indexPath: startPickerPath)
        }
        else if calendar == endDatePicker {
            self.endDate.text = dateFormatter.string(from: date)
            changeTextFieldToWhite(indexPath: endPickerPath)
        }
    }
}
