//
//  Queue.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/23.
//

import Foundation

struct Queue<T> {
    private var queue: [T] = []

    public var count: Int {
        return queue.count
    }

    public var isEmpty: Bool {
        return queue.isEmpty
    }

    public mutating func enqueue(_ element: T) {
        queue.append(element)
    }

    public mutating func dequeue() -> T? {
        return isEmpty ? nil : queue.removeFirst()
    }
}
