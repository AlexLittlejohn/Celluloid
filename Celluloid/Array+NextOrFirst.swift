//
//  Array+NextOrFirst.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 16/09/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation

extension Array where Element : Equatable {

    /// Returns the next element in an array of Equatable elements if the element provided is at the end otherwise return the first element
    ///
    /// - parameter after: The current element to search after
    ///
    /// - returns: The next element
    func nextOrFirst(after: Array.Element) -> Element? {

        guard let idx = index(of: after) else {
            return nil
        }

        if idx < count - 2 {
            return self[idx + 1]
        } else {
            return first
        }
    }
}
