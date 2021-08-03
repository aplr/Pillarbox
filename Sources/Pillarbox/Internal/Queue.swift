//
//  Queue.swift
//  Pillarbox
//
//  Created by Andreas Pfurtscheller on 29.04.21.
//

import DequeModule
import Foundation

@usableFromInline
class Queue<Element>: Codable where Element: Codable {
    
    private var queue: Deque<Element>
    
    @usableFromInline
    var strategy: PillarboxQueueStrategy = .lifo
    
    init() {
        queue = Deque()
    }
    
    @usableFromInline
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        self.queue = try container.decode(Deque<Element>.self)
    }
    
    @usableFromInline
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        try container.encode(queue)
    }
    
    @usableFromInline
    func peek() -> Element? {
        switch strategy {
        case .fifo: return queue.first
        case .lifo: return queue.last
        }
    }
    
    @usableFromInline
    func peek(offset: Int) -> Element? {
        switch strategy {
        case .fifo: return queue[safe: queue.index(queue.startIndex, offsetBy: offset)]
        case .lifo: return queue[safe: queue.index(queue.endIndex, offsetBy: -offset) - 1]
        }
    }
    
    @usableFromInline
    func pop() -> Element? {
        switch strategy {
        case .fifo: return queue.popFirst()
        case .lifo: return queue.popLast()
        }
    }
    
    @usableFromInline
    func push(_ element: Element) {
        queue.append(element)
    }
    
    @usableFromInline
    func remove(where predicate: (Element) throws -> Bool) rethrows {
        if let index = try queue.firstIndex(where: predicate) {
            queue.remove(at: index)
        }
    }
    
    @usableFromInline
    var isEmpty: Bool {
        queue.isEmpty
    }
    
    @usableFromInline
    var count: Int {
        queue.count
    }
    
    @usableFromInline
    var elements: [Element] {
        Array(queue)
    }
}

extension Queue where Element: Equatable {
    
    @usableFromInline
    func remove(_ element: Element) {
        if let index = queue.firstIndex(of: element) {
            queue.remove(at: index)
        }
    }
}
