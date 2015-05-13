//
// PagedArray.swift
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

///
/// A paging collection type for arbitrary elements. Great for implementing paging
/// mechanisms when providing data read from slow I/O to scrolling UI elements
/// such as `UICollectionView` and `UITableView`.
///
public struct PagedArray<T> {
    private typealias Element = T
    
    /// The datastorage
    public private(set) var pages = [Int: [Element]]()
    
    // MARK: Public properties
    
    /// The size of each page
    public let pageSize: Int
    
    /// The total count of supposed elements, including nil values
    public var count: Int
    
    /// The starting page index
    public let startPage: Int
    
    /// The last valid page index
    public var lastPage: Int {
        if self.count == 0 {
            return startPage
        }
        var result = (count/pageSize) + startPage
        if (count % pageSize) == 0 {
            result--
        }
        if result < 0 {
            result = 0
        }
        return result
    }
    
    /// All elements currently set, in order
    public var loadedElements: [Element] {
        var result: [Element] = []
        for var i=startPage; i <= lastPage; i++ {
            if let elements = self.elementsForPage(i) {
                result += elements
            }
        }
        return result
    }
    
    // MARK: Initializers
    
    /// Creates an empty `PagedArray`
    public init(count: Int, pageSize: Int, startPage: Int) {
        self.count = count
        self.pageSize = pageSize
        self.startPage = startPage
    }
    
    /// Creates an empty `PagedArray` with a default 0 `startPage` index
    public init(count: Int, pageSize: Int) {
        self.count = count
        self.pageSize = pageSize
        self.startPage = 0
    }
    
    // MARK: Public functions
    
    /// Returns the page index for an element index
    public func pageNumberForIndex(index: Index) -> Int {
        assert(index >= startIndex || index <= endIndex, "Index out of bounds")
        return index/pageSize+startPage
    }
    
    /// Returns a `Range` corresponding to the indexes for a page
    public func indexesForPage(page: Int) -> Range<Index> {
        assert(page >= startPage && page <= lastPage, "Page index out of bounds")
        
        let startIndex: Index = (page-startPage)*pageSize
        let endIndex: Index
        if page == lastPage {
            endIndex = count
        } else {
            endIndex = startIndex+pageSize
        }
        
        return (startIndex..<endIndex)
    }
    
    // MARK: Public mutating functions
    
    /// Sets a page of elements for a page index
    public mutating func setElements(elements: [Element], page: Int) {
        assert(page >= startPage && page <= lastPage, "Page index out of bounds")
        if page != lastPage {
            assert(elements.count == pageSize, "Invalid elements count for page")
        }
        
        pages[page] = elements
    }
    
    /// Removes the elements corresponding to the page, replacing them with `nil` values
    public mutating func removePage(pageNumber: Int) {
        pages[pageNumber] = nil
    }
    
    /// Removes all loaded elements, replacing them with `nil` values
    public mutating func removeAllPages() {
        pages.removeAll(keepCapacity: true)
    }
    
    public mutating func appendElement(element: Element) {
        let loadedCount: Int = self.loadedElements.count
        let page = self.pageNumberForIndex(loadedCount-1)
        var elements = self.elementsForPage(page)
        if var elements = elements {
            if (elements.count == pageSize) {
                let newPageElements: [Element] = [element]
                pages[page+1] = newPageElements
            } else {
                elements.append(element)
                pages[page] = elements
            }
        }
        count++
    }
    
    public mutating func deleteElement(atIndex index: Int) {
        let page = self.pageNumberForIndex(index)
        var elements = self.elementsForPage(page)
        if var elements = elements {
            let indexAtPage = index - ((page - self.startPage) * pageSize)
            elements.removeAtIndex(indexAtPage)
            pages[page] = elements
            
            for var i=(page); i < self.lastPage; i++ {
                let elements: [Element]? = pages[i]
                if let elements = elements where elements.count > 0 {
                    self.moveFirstElement(fromPage: i+1, toLastPositionInPage: i)
                }
                let newElementsInPage = pages[i]
                if let newElementsInPage = newElementsInPage where newElementsInPage.count < pageSize {
                    self.removePage(i)
                }
            }
            self.count--
        }
        //TODO: notify if there is no elements?
    }
    
    public mutating func moveElement(#fromIndex: Int, toIndex: Int) {
        
        // same index - nothing to do
        if (fromIndex == toIndex) {
            return
        }
        
        // we need the pages for both indexes
        let fromIndexPage = self.pageNumberForIndex(fromIndex)
        let toIndexPage = self.pageNumberForIndex(toIndex)
        
        // the elemetns are in the same Page
        if (fromIndexPage == toIndexPage) {
            
            // we need the indexes converted to indexes valid inside the Page
            let fromIndexInPage: Int = fromIndex % pageSize
            let toIndexInPage: Int = toIndex % pageSize
            
            // get the elements in the page
            let maybeElements = self.elementsForPage(fromIndexPage)
            assert(maybeElements != nil, "No elements in the page")
            var elements = maybeElements!
            
            // remove the element we are going to move
            var elementFrom = elements.removeAtIndex(fromIndexInPage)
            
            // check if we are moving the element to the latest position
            // we should append then
            if (toIndexInPage >= elements.count) {
                elements.append(elementFrom)
            } else {
                elements.insert(elementFrom, atIndex: toIndexInPage)
            }
            // put back the elements in the page
            pages[fromIndexPage] = elements
            return
        }
        
        // elements are not in the same page
        // let's find out what is the index relative to the page of the element
        let fromIndexInPage: Int = fromIndex % pageSize
        // get the elements in the page
        var maybeElementsInFromIndexPage = self.elementsForPage(fromIndexPage)
        assert(maybeElementsInFromIndexPage != nil, "No elements in the page")
        var elementsInFromIndexPage: [Element] = maybeElementsInFromIndexPage!
        // remove the element to move
        let elementToMoveFrom = elementsInFromIndexPage.removeAtIndex(fromIndexInPage)
        pages[fromIndexPage] = elementsInFromIndexPage;
        
        // if we are going up
        if (fromIndexPage > toIndexPage) {
            // go through the pages until we reach the destination page
            // we have to bubble the elements up
            for var i=(fromIndexPage-1); i >= toIndexPage; i-- {
                if (i != toIndexPage) {
                    // start moving the last element of this Page to the first position
                    // of the next consecutive page
                    self.moveLastElement(fromPage: i, toFirstPositionInPage: i+1)
                } else {
                    // we reached the final page
                    // insert the element we are moving and
                    // push down the last element in the page
                    let toIndexInPage: Int = toIndex % pageSize
                    let maybeElementsInToIndexPage = self.elementsForPage(i)
                    assert(maybeElementsInToIndexPage != nil, "No elements in the page")
                    var elementsInToIndexPage = maybeElementsInToIndexPage!
                    elementsInToIndexPage.insert(elementToMoveFrom, atIndex: toIndexInPage)
                    pages[i] = elementsInToIndexPage
                    self.moveLastElement(fromPage: i, toFirstPositionInPage: i+1)
                }
            }
        // if we are going down
        } else if (fromIndexPage < toIndexPage) {
            // go through the pages until we reach the destination page
            // we have to bubble the elements down
            for var i=(fromIndexPage); i <= toIndexPage; i++ {
                if (i != toIndexPage) {
                    // start moving the first element of the consecutive page to the last position
                    // of the current Page
                    self.moveFirstElement(fromPage: i+1, toLastPositionInPage: i)
                } else {
                    // we reached the final page
                    // insert the element we are moving
                    let toIndexInPage: Int = toIndex % pageSize
                    var maybeElementsInToIndexPage = self.elementsForPage(i)
                    assert(maybeElementsInToIndexPage != nil, "No elements in the page")
                    var elementsInToIndexPage = maybeElementsInToIndexPage!
                    elementsInToIndexPage.insert(elementToMoveFrom, atIndex: toIndexInPage)
                    pages[i] = elementsInToIndexPage
                }
            }
        }
    }
    
    // MARK: Private mutating functions
    
    private mutating func moveLastElement(#fromPage: Int, toFirstPositionInPage toPage: Int) {
        var maybeElements = self.elementsForPage(fromPage)
        assert(maybeElements != nil, "No elements in the page")
        var elements = maybeElements!
        var elementsBelow = self.elementsForPage(toPage)
        if var elementsBelow = elementsBelow {
            elementsBelow.insert(elements.removeLast(), atIndex: 0)
            pages[fromPage] = elements
            pages[toPage] = elementsBelow
        } else {
            pages[toPage] = [elements.removeLast()]
            pages[fromPage] = elements
        }
    }
    
    private mutating func moveFirstElement(#fromPage: Int, toLastPositionInPage toPage: Int) {
        var elements = self.elementsForPage(fromPage)
        if var elements = elements {
            var maybeElementsAbove = self.elementsForPage(toPage)
            assert(maybeElementsAbove != nil, "No elements in the page")
            var elementsAbove = maybeElementsAbove!
            if ((pageSize-1) >= elementsAbove.count) {
                elementsAbove.append(elements.removeAtIndex(0))
            } else {
                elementsAbove.insert(elements.removeAtIndex(0), atIndex: (pageSize-1))
            }
            pages[fromPage] = elements
            pages[toPage] = elementsAbove
        }
    }
    
    private func elementsForPage(index: Index) -> [Element]? {
        let page = self.pageNumberForIndex(index)
        var elementsInDestinationPage: [Element]? = pages[index]
        return elementsInDestinationPage
    }
}

// MARK: Higher order functions

extension PagedArray {
    
    /// Returns a filtered `Array` of optional elements filtered by `includeElement` function
    public func filter(includeElement: (T?) -> Bool) -> [T?] {
        return Array(self).filter(includeElement)
    }
    
    /// Returns an `Array` where each optional element is transformed by provided `transform`
    public func map<U>(transform: (T?) -> U) -> [U] {
        return Array(self).map(transform)
    }
    
    // Returns a single value by iteratively combining each element
    public func reduce<U>(var initial: U, combine: (U, T?) -> U) -> U {
        return Swift.reduce(self, initial, combine)
    }
}

// MARK: SequenceType

extension PagedArray : SequenceType {
    public func generate() -> IndexingGenerator<PagedArray> {
        return IndexingGenerator(self)
    }
}

// MARK: CollectionType

extension PagedArray : CollectionType {
    public typealias Index = Int
    
    public var startIndex: Index { return 0 }
    public var endIndex: Index { return count }
    
    public subscript (index: Index) -> Element? {
        
        get {
            let pageNumber = pageNumberForIndex(index)
            
            if let page = pages[pageNumber] {
                return page[index%pageSize]
            } else {
                // Return nil for all pages that haven't been set yet
                return nil
            }
        }
        set {
            if let value = newValue {
                let page = self.pageNumberForIndex(index)
                var elements: [Element] = self.elementsForPage(page)!
                elements[index%pageSize] = value
                pages[page] = elements
            }
        }
    }
}

// MARK: Printable

extension PagedArray : Printable {
    public var description: String {
        return "PagedArray(\(Array(self)))"
    }
}

// MARK: DebugPrintable

extension PagedArray : DebugPrintable {
    public var debugDescription: String {
        return "PagedArray(Pages: \(pages), Array representation: \(Array(self)))"
    }
}

