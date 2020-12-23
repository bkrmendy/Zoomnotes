//
//  LWWRegister.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 12. 22..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation
import GRDB

protocol LWWRegister: Column {
    typealias TieBreakFn = (Value, Value) -> Value

    var tieBreak: TieBreakFn { get }

    func get(db: DatabaseQueue, for entity: UUID) throws -> Value?
}
