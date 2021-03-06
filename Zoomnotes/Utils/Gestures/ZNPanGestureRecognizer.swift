//
//  GestureRecognizer+Closure.swift
//  Zoomnotes
//
//  Created by Berci on 2020. 08. 24..
//  Copyright © 2020. Berci. All rights reserved.
//

import Foundation
import UIKit

final class ZNPanGestureRecognizer<State>: UIPanGestureRecognizer {
    typealias StateManager = ZNStatefulGestureManager<State, UIPanGestureRecognizer>
    private let stateManager: StateManager
    init(begin: @escaping StateManager.Begin,
         step: @escaping StateManager.Step,
         end: @escaping StateManager.End) {
        self.stateManager = StateManager(begin: begin, step: step, end: end)

        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
    }

    func touches(_ count: Int) -> Self {
        self.minimumNumberOfTouches = count
        self.maximumNumberOfTouches = count

        return self
    }

    @objc private func execute(_ recognizer: UIPanGestureRecognizer) {
        self.stateManager.do(recognizer)
    }
}
