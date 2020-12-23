//
//  Column.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 12. 23..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation
import GRDB

protocol Column {
    associatedtype Value
    var name: String { get }
    func create(db: DatabaseQueue) throws
    func `assert`(db: DatabaseQueue, entity: UUID, value: Value, timestamp: UInt64) throws
    func retract(db: DatabaseQueue, entity: UUID, value: Value, timestamp: UInt64) throws
}
