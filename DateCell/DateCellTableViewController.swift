//
//  DateCellTableViewController.swift
//  DateCell
//
//  Created by Kohei Hayakawa on 2/6/15.
//  Copyright (c) 2015 Kohei Hayakawa. All rights reserved.
//

import UIKit

class DateCellTableViewController: UITableViewController {
    
    let pickerAnimationDuration = 0.4
    let datePickerTag           = 99
    let titleKey = "title"
    let dateKey  = "date"
    let dateStartRow = 0
    let dateEndRow   = 1
    let dateCellID       = "dateCell";
    let datePickerCellID = "datePickerCell";

    var dataArray: [[String: AnyObject]] = []
    lazy var dateFormatter : DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter
    }()
    
    var datePickerIndexPath: NSIndexPath?
    var pickerCellRowHeight: CGFloat = 382 // 216 for wheels
    
    @IBOutlet var pickerView: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        let dateItemOne = [titleKey : "De", dateKey : NSDate()] as [String : Any]
        let dateItemTwo = [titleKey : "A", dateKey : NSDate()] as [String : Any]
        
        dataArray = [dateItemOne as Dictionary<String, AnyObject>, dateItemTwo as Dictionary<String, AnyObject>]

        NotificationCenter.default.addObserver(self, selector: #selector(DateCellTableViewController.localeChanged(notif:)), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
    }

    
    // MARK: - Locale

    @objc func localeChanged(notif: NSNotification) {
        tableView.reloadData()
    }
    

    func hasPickerForIndexPath(indexPath: NSIndexPath) -> Bool {
        var hasDatePicker = false
        
        let targetedRow = indexPath.row + 1
        let checkDatePickerCell = tableView.cellForRow(at: IndexPath(row: targetedRow, section: 0))
        let checkDatePicker = checkDatePickerCell?.viewWithTag(datePickerTag)
        
        hasDatePicker = checkDatePicker != nil
        return hasDatePicker
    }


    func updateDatePicker() {
        if let indexPath = datePickerIndexPath {
            let associatedDatePickerCell = tableView.cellForRow(at: indexPath as IndexPath)
            if let targetedDatePicker = associatedDatePickerCell?.viewWithTag(datePickerTag) as! UIDatePicker? {
                let itemData = dataArray[self.datePickerIndexPath!.row - 1]
                targetedDatePicker.setDate(itemData[dateKey] as! Date, animated: false)
            }
        }
    }
    
 
    func hasInlineDatePicker() -> Bool {
        return datePickerIndexPath != nil
    }
    

    func indexPathHasPicker(indexPath: NSIndexPath) -> Bool {
        return hasInlineDatePicker() && datePickerIndexPath?.row == indexPath.row
    }


    func indexPathHasDate(indexPath: NSIndexPath) -> Bool {
        var hasDate = false
        
        if (indexPath.row == dateStartRow) || (indexPath.row == dateEndRow || (hasInlineDatePicker() && (indexPath.row == dateEndRow + 1))) {
            hasDate = true
        }
        return hasDate
    }

    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPathHasPicker(indexPath: indexPath as NSIndexPath) ? pickerCellRowHeight : tableView.rowHeight)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasInlineDatePicker() {
            return dataArray.count + 1;
        }
        
        return dataArray.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        var cellID = dateCellID
        
        if indexPathHasPicker(indexPath: indexPath as NSIndexPath) {
            cellID = datePickerCellID     // the current/opened date picker cell
        }
        
        cell = tableView.dequeueReusableCell(withIdentifier: cellID)
    
        if indexPath.row == 0 {
            cell?.selectionStyle = .none;
        }
        
        var modelRow = indexPath.row
        if (datePickerIndexPath != nil && (datePickerIndexPath?.row)! <= indexPath.row) {
            modelRow -= 1
        }
        
        let itemData = dataArray[modelRow]
        
        if cellID == dateCellID {
            cell?.textLabel?.text = itemData[titleKey] as? String
            cell?.detailTextLabel?.text = self.dateFormatter.string(from: (itemData[dateKey] as! NSDate) as Date)
        }
        
        return cell!
    }
    

    func toggleDatePickerForSelectedIndexPath(indexPath: NSIndexPath) {
        tableView.beginUpdates()
        
        let indexPaths = [IndexPath(row: indexPath.row + 1, section: 0)]

        if hasPickerForIndexPath(indexPath: indexPath) {
            tableView.deleteRows(at: indexPaths as [IndexPath], with: .fade)
        } else {
            tableView.insertRows(at: indexPaths as [IndexPath], with: .fade)
        }
        
        tableView.endUpdates()
    }


    func displayInlineDatePickerForRowAtIndexPath(indexPath: NSIndexPath) {
        tableView.beginUpdates()
        
        var before = false
        if hasInlineDatePicker() {
            before = (datePickerIndexPath?.row)! < indexPath.row
        }
        
        let sameCellClicked = (datePickerIndexPath?.row == indexPath.row + 1)
        
        if self.hasInlineDatePicker() {
            tableView.deleteRows(at: [IndexPath(row: datePickerIndexPath!.row, section: 0)], with: .fade)
            datePickerIndexPath = nil
        }
        
        if !sameCellClicked {
            let rowToReveal = (before ? indexPath.row - 1 : indexPath.row)
            let indexPathToReveal =  IndexPath(row: rowToReveal, section: 0)

            toggleDatePickerForSelectedIndexPath(indexPath: indexPathToReveal as NSIndexPath)
            datePickerIndexPath = IndexPath(row: indexPathToReveal.row + 1, section: 0) as NSIndexPath
        }
        
        tableView.deselectRow(at: indexPath as IndexPath, animated:true)
        tableView.endUpdates()
        updateDatePicker()
    }
    
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath as IndexPath)
        if cell?.reuseIdentifier == dateCellID {
            displayInlineDatePickerForRowAtIndexPath(indexPath: indexPath as NSIndexPath)
        } else {
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        }
    }
    
    
    // MARK: - Actions
    @IBAction func dateAction(_ sender: UIDatePicker) {
        var targetedCellIndexPath: NSIndexPath?
        
        if self.hasInlineDatePicker() {
            targetedCellIndexPath = IndexPath(row: datePickerIndexPath!.row - 1, section: 0) as NSIndexPath
            
        } else {
            targetedCellIndexPath = tableView.indexPathForSelectedRow! as NSIndexPath
        }
        
        let cell = tableView.cellForRow(at: targetedCellIndexPath! as IndexPath)
        let targetedDatePicker = sender
        
        var itemData = dataArray[targetedCellIndexPath!.row]
        itemData[dateKey] = targetedDatePicker.date as AnyObject
        dataArray[targetedCellIndexPath!.row] = itemData
       
        cell?.detailTextLabel?.text = dateFormatter.string(from: targetedDatePicker.date)
    }

}

