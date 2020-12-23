//
//  LWWRegisterInt.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 12. 23..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation
import GRDB

struct IntRow {
    let entity_id: String
    let value: Int
    let deleted: Bool
    let timestamp: UInt64
}

enum Columns: String {
    case entity_id
    case deleted
    case value
    case timestamp
}

extension IntRow: PersistableRecord {
    func encode(to container: inout PersistenceContainer) {
        container[Columns.entity_id.rawValue] = entity_id
        container[Columns.deleted.rawValue] = deleted
        container[Columns.value.rawValue] = value
        container[Columns.timestamp.rawValue] = timestamp
    }
}

extension IntRow: FetchableRecord {
    init(row: Row) {
        self.entity_id = row[Columns.entity_id.rawValue]
        self.value = Int(row[Columns.value.rawValue])!
        self.deleted = row[Columns.deleted.rawValue]
        self.timestamp = row[Columns.timestamp.rawValue]
    }
}

class LWWRegisterInt: LWWRegister {
    let name: String

    let tieBreak: TieBreakFn = min

    init(name: String) {
        self.name = name
    }

    func create(db: DatabaseQueue) throws {
        try db.write { [unowned self] dbi in
            try dbi.create(table: self.name) { t in
                t.column(Columns.entity_id.rawValue, .text)
                t.column(Columns.deleted.rawValue, .boolean)
                t.column(Columns.value.rawValue, .integer)
                t.column(Columns.timestamp.rawValue, .integer)
            }
        }
    }

    func assert(db: DatabaseQueue, entity: UUID, value: Int, timestamp: UInt64) throws {
        try db.inTransaction { dbt in
            try dbt.execute(
                sql: """
                    DELETE FROM \(name)
                    WHERE \(Columns.timestamp) <= :timestamp
                        AND (\(Columns.deleted) OR \(Columns.entity_id) = :entity_id);
                    """,
                arguments: [timestamp, entity.uuidString])

            try IntRow(entity_id: entity.uuidString,
                   value: value,
                   deleted: false,
                   timestamp: timestamp).insert(dbt)
            return .commit
        }
    }

    func retract(db: DatabaseQueue, entity: UUID, value: Int, timestamp: UInt64) throws {
        try db.inTransaction { dbt in
            try dbt.execute(
                sql: """
                    DELETE FROM \(name)
                    WHERE \(Columns.timestamp) <= :timestamp
                        AND (\(Columns.deleted) OR \(Columns.entity_id) = :entity_id);
                    """,
                arguments: [timestamp, entity.uuidString])
            
            try IntRow(entity_id: entity.uuidString,
                   value: value,
                   deleted: true,
                   timestamp: timestamp).insert(dbt)
            return .commit
        }
    }

    func get(db: DatabaseQueue, for entity: UUID) throws -> Int? {
        try db.read { dbi in
            dbi.sele

        }
        return 0
    }
}
