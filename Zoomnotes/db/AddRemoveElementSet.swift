//
//  AddRemoveElementSet.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 12. 22..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation

protocol AddRemoveElementSet {
    associatedtype Value
    func `assert`(entity: UUID, value: Value)
    func retract(entity: UUID, value: Value)
    func get(for entity: UUID) -> [Value]
}
