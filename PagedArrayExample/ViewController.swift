//
// ViewController.swift
//
// Created by Alek Åström on 2015-02-14.
// Copyright (c) 2015 Alek Åström. (https://github.com/MrAlek)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import PagedArray

// Tweak these values and see how the user experience is affected
let PreloadMargin = 10 /// How many rows "in front" should be loaded
let PageSize = 25 /// Paging size
let DataLoadingOperationDuration = 0.5 /// Simulated network operation duration
let TotalCount = 200 /// Number of rows in table view

// This is our database
var datasource: [String] = []

class ViewController: UITableViewController {

    let cellIdentifier = "Cell"
    let operationQueue = NSOperationQueue()
    
    var pagedArray = PagedArray<String>(count: TotalCount, pageSize: PageSize)
    var dataLoadingOperations = [Int: NSOperation]()
    var shouldPreload = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
            self.navigationItem.rightBarButtonItems = [self.addBtn, self.editBtn]
        
        for (var i=0; i < TotalCount; i++) {
            datasource.append("Content data \(i)")
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    private var editBtn:UIBarButtonItem {
        get {
            return UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Edit, target: self, action: "barButtonItemReorderTouched")
        }
    }
    
    private var doneBtn:UIBarButtonItem {
        get {
            return UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "barButtonItemReorderTouched")
        }
    }
    
    private var addBtn:UIBarButtonItem {
        get {
            return UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "barButtonItemAddTouched")
        }
    }
    
    // MARK: User actions
    
    @IBAction func clearDataPressed() {
        if (self.tableView.editing) {
            self.navigationItem.rightBarButtonItems = [self.editBtn]
        }
        self.tableView.setEditing(false, animated: true)
        dataLoadingOperations.removeAll(keepCapacity: true)
        operationQueue.cancelAllOperations()
        pagedArray.removeAllPages()
        tableView.reloadData()
    }
    
    @IBAction func preLoadingSwitchChanged(sender: UISwitch) {
        shouldPreload = sender.on
    }
    
    // MARK: Private functions
    
    func barButtonItemReorderTouched() {
        
        if (self.tableView.editing) {
            self.navigationItem.rightBarButtonItems = [self.addBtn, self.editBtn]
        } else {
            self.navigationItem.rightBarButtonItems = [self.addBtn, self.doneBtn]
        }
        self.tableView.setEditing(!self.tableView.editing, animated: true)
    }
    
    func barButtonItemAddTouched() {
        let newElement = "New content \(NSDate.new())"
        
        let indexsPathToAdd: [NSIndexPath] = [NSIndexPath(forRow: self.pagedArray.count, inSection: 0)];
        self.pagedArray.appendElement(newElement)
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths(indexsPathToAdd, withRowAnimation: UITableViewRowAnimation.Fade)
        self.tableView.endUpdates()
        
        datasource.append(newElement)
    }
    
    private func configureCell(cell: UITableViewCell, data: String?) {
        if let data = data {
            cell.textLabel?.text = data
        } else {
            cell.textLabel?.text = " "
        }
    }
    
    private func loadDataIfNeededForRow(row: Int) {
        
        let currentPage = pagedArray.pageNumberForIndex(row)
        if needsLoadDataForPage(currentPage) {
            loadDataForPage(currentPage)
        }
        
        let preloadIndex = row+PreloadMargin
        if preloadIndex < pagedArray.endIndex && shouldPreload {
            let preloadPage = pagedArray.pageNumberForIndex(preloadIndex)
            if preloadPage > currentPage && needsLoadDataForPage(preloadPage) {
                loadDataForPage(preloadPage)
            }
        }
    }
    
    private func needsLoadDataForPage(page: Int) -> Bool {
        return pagedArray.pages[page] == nil && dataLoadingOperations[page] == nil
    }
    
    private func loadDataForPage(page: Int) {
        let indexes = pagedArray.indexesForPage(page)

        // Create loading operation
        let operation = DataLoadingOperation(indexesToLoad: indexes) { [unowned self] indexes, data in
            
            // Set elements on paged array
            self.pagedArray.setElements(data, page: page)
            
            // Loop through and update visible rows that got new data
            for row in self.visibleRowsForIndexes(indexes) {
                self.configureCell(self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))!, data: self.pagedArray[row])
            }
            
            self.dataLoadingOperations[page] = nil
        }

        // Add operation to queue and save it
        operationQueue.addOperation(operation)
        dataLoadingOperations[page] = operation
    }
    
    private func visibleRowsForIndexes(indexes: Range<Int>) -> [Int] {
        let visiblePaths = self.tableView.indexPathsForVisibleRows() as! [NSIndexPath]
        let visibleRows = visiblePaths.map { $0.row }
        return visibleRows.filter { find(indexes, $0) != nil }
    }
    
}

// MARK: Table view datasource
extension ViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pagedArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        loadDataIfNeededForRow(indexPath.row)

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! UITableViewCell
        configureCell(cell, data: pagedArray[indexPath.row])
        return cell
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.pagedArray.moveElement(fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
        let fromElement = datasource.removeAtIndex(sourceIndexPath.row)
        datasource.insert(fromElement, atIndex: destinationIndexPath.row)
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var actions : [AnyObject] = [];
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete") { [weak self] (action, indexPath) -> Void in
            if let actualSelf = self {
                datasource.removeAtIndex(indexPath.row)
                let page: Int = actualSelf.pagedArray.pageNumberForIndex(actualSelf.pagedArray.count)
                let indexsPathToRemove: [NSIndexPath] = [NSIndexPath(forRow: indexPath.row, inSection: 0)];
                actualSelf.tableView.beginUpdates()
                actualSelf.tableView.deleteRowsAtIndexPaths(indexsPathToRemove, withRowAnimation: UITableViewRowAnimation.Fade)
                actualSelf.pagedArray.deleteElement(atIndex: indexPath.row)
                actualSelf.tableView.endUpdates()
            }
        }
        actions.append(delete);
        return actions;
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}


/// Test operation that produces nonsense numbers as data
class DataLoadingOperation: NSBlockOperation {
    
    init(indexesToLoad: Range<Int>, completion: (indexes: Range<Int>, data: [String]) -> Void) {
        super.init()
        
        println("Loading indexes: \(indexesToLoad)")
        
        addExecutionBlock {
            // Simulate loading
            NSThread.sleepForTimeInterval(DataLoadingOperationDuration)
        }
        
        completionBlock = {
            let data:[String] = [] + datasource[indexesToLoad]
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                completion(indexes: indexesToLoad, data: data)
            }
        }
    }
    
}
