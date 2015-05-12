//
//  ExtPagedArrayTests.swift
//  PagedArray
//
//  Created by Alejandro Diego Garin on 5/11/15.
//  Copyright (c) 2015 Apps and Wonders. All rights reserved.
//

import UIKit
import XCTest
import PagedArray

class ExtPagedArrayTests: XCTestCase {

    let ArrayCount = 100
    let PageSize = 15
    let StartPage = 1
    
    var pagedArray: PagedArray<Int>!
    
    var firstPage: [Int]!
    var secondPage: [Int]!
    var thridPage: [Int]!
    
    override func setUp() {
        super.setUp()
        
        pagedArray = PagedArray(count: ArrayCount, pageSize: PageSize, startPage: StartPage)
        
        // Fill up two pages
        firstPage = Array(1...PageSize)
        secondPage = Array(PageSize+1...PageSize*2)
        thridPage = Array(31...PageSize*3)
        
        pagedArray.setElements(firstPage, page: StartPage)
        pagedArray.setElements(secondPage, page: StartPage+1)
        pagedArray.setElements(thridPage, page: StartPage+2)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoadedElementsForOnePageAndAHalfOfTheLastOne() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 15, pageSize: 10)
        tinyArray.setElements(Array(0...9), page: 0)
        tinyArray.setElements(Array(10...11), page: 1)
        XCTAssertEqual(tinyArray.loadedElements.count, 12, "Array total count is not correct")
    }
    
    func testLoadedElementAddedNotInOrder() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 40, pageSize: 10)
        tinyArray.setElements(Array(10...19), page: 1)
        tinyArray.setElements(Array(20...29), page: 2)
        tinyArray.setElements(Array(0...9), page: 0)
        tinyArray.setElements(Array(30...39), page: 3)
        XCTAssertEqual(tinyArray.loadedElements, Array(0...39))
    }
    
    func testGetLastPageNumberExactCountPageSizeDivision() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10)
        XCTAssertEqual(tinyArray.lastPage, 2)
    }
    
    func testGetLastPageNumberExactCountPageSizeDivisionWithStartingPage1() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10, startPage: 1)
        XCTAssertEqual(tinyArray.lastPage, 3)
    }
    
    func testGetLastPageNumberExactCountPageSizeDivisionWithStartingPage10() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10, startPage: 10)
        XCTAssertEqual(tinyArray.lastPage, 12)
    }
    
    func testGetLastPageNumberNotExactCountPageSizeDivision() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 100, pageSize: 15)
        XCTAssertEqual(tinyArray.lastPage, 6)
    }
    
    func testGetLastPageNumberNotExactCountPageSizeDivisionStartingPage1() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 100, pageSize: 15, startPage: 1)
        XCTAssertEqual(tinyArray.lastPage, 7)
    }
    
    func testGetLastPageNumberNotExactCountPageSizeDivisionStartingPage10() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 100, pageSize: 15, startPage: 10)
        XCTAssertEqual(tinyArray.lastPage, 16)
    }
    
    func testMoveElementsBetweenConsecutivePagesUp() {
        pagedArray.moveElement(fromIndex: 29, toIndex: 0)
        XCTAssertEqual(30, pagedArray[0]!, "This position should contain the moved element");
        XCTAssertEqual(1, pagedArray[1]!);
        XCTAssertEqual(29, pagedArray[29]!);
    }
    
    func testMoveElementsBetweenConsecutivePagesDown() {
        pagedArray.moveElement(fromIndex: 0, toIndex: 29)
        XCTAssertEqual(2, pagedArray[0]!);
        XCTAssertEqual(3, pagedArray[1]!);
        XCTAssertEqual(1, pagedArray[29]!, "This position should contain the moved element");
    }
    
    func testMoveElementInSamePageUp() {
        pagedArray.moveElement(fromIndex: 29, toIndex: 28)
        XCTAssertEqual(28, pagedArray[27]!);
        XCTAssertEqual(30, pagedArray[28]!, "This should be the moved element");
        XCTAssertEqual(29, pagedArray[29]!, "This element is the one the was where the moved element was located");
    }
    
    func testMoveElementInSamePageDown() {
        pagedArray.moveElement(fromIndex: 0, toIndex: 3)
        XCTAssertEqual(2, pagedArray[0]!);
        XCTAssertEqual(3, pagedArray[1]!);
        XCTAssertEqual(4, pagedArray[2]!);
        XCTAssertEqual(1, pagedArray[3]!, "First element should have been moved to this position");
        XCTAssertEqual(5, pagedArray[4]!);
    }
    
    func testMoveElementsBetweenNotConsecutivePagesUp() {
        pagedArray.moveElement(fromIndex: 44, toIndex: 0)
        XCTAssertEqual(45, pagedArray[0]!, "This position should contain the moved element");
        XCTAssertEqual(1, pagedArray[1]!);
        XCTAssertEqual(44, pagedArray[44]!);
    }
    
    func testMoveElementsBetweenNotConsecutivePagesDown() {
        pagedArray.moveElement(fromIndex: 0, toIndex: 44)
        XCTAssertEqual(2, pagedArray[0]!);
        XCTAssertEqual(3, pagedArray[1]!);
        XCTAssertEqual(1, pagedArray[44]!, "This position should contain the moved element");
    }
    
    func testAssignNewElement() {
        pagedArray[10] = 77
        XCTAssertEqual(77, pagedArray[10]!, "The new value for position 10 should be 77");
    }
    
    func testDeleteElementAtIndex() {
        pagedArray.deleteElement(atIndex: 40)
        XCTAssertEqual(pagedArray.loadedElements.count, firstPage.count + secondPage.count, "Array total count is not correct")
    }
    
    func testDeleteElementNotConsecutivePages() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10)
        tinyArray.setElements(Array(0...9), page: 0)
        tinyArray.setElements(Array(10...19), page: 1)
        tinyArray.setElements(Array(20...22), page: 2)

        tinyArray.deleteElement(atIndex: 0)
        tinyArray.deleteElement(atIndex: 10)
        tinyArray.deleteElement(atIndex: 20)
        XCTAssertEqual(tinyArray.loadedElements.count, 20, "Array total count is not correct")
        XCTAssertEqual(tinyArray.loadedElements, Array(1...10) + Array(12...21))
        XCTAssertEqual(tinyArray.pages.count, 3)
    }
    
    func testDeleteElementWhereMiddlePageGetNotFull() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10)
        tinyArray.setElements(Array(0...9), page: 0)
        tinyArray.setElements(Array(10...19), page: 1)
        
        tinyArray.deleteElement(atIndex: 10)
        XCTAssertEqual(tinyArray.loadedElements.count, 10, "Array total count is not correct")
    }
    
    func testInsertElementInCompletePages() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 20, pageSize: 10)
        tinyArray.setElements(Array(0...9), page: 0)
        tinyArray.setElements(Array(10...19), page: 1)
        
        tinyArray.appendElement(20)
        
        XCTAssertEqual(tinyArray.loadedElements.count, 21, "Array total count is not correct")
    }
    
    func testInsertElementInNotCompletePage() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 20, pageSize: 10)
        tinyArray.setElements(Array(0...9), page: 0)
        tinyArray.setElements(Array(10...12), page: 1)
        
        tinyArray.appendElement(13)
        
        XCTAssertEqual(tinyArray.loadedElements.count, 14, "Array total count is not correct")
    }
    
    func testSetElementsFirstPage() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 0, pageSize: 10)
        tinyArray.setElements(Array(), page: 0)
    }
    
}
