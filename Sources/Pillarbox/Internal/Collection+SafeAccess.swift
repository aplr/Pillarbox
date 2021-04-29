//
//  Collection+SafeAccess.swift
//  Core
//
//  Created by Andreas Pfurtscheller on 15.03.21.
//  Copyright © 2020 M-Pulso GmbH. All rights reserved.
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    /// Watch out as this one can be quite expensive, since the contains() is O(n)
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
