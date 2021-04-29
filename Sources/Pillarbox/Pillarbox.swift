//
//  Pillarbox.swift
//  Pillarbox
//
//  Created by Andreas Pfurtscheller on 07.04.21.
//

import Foundation

/// The queuing strategy to use when peeking and popping items off the queue.
public enum PillarboxQueueStrategy {
    
    /// When using the first in first out strategy, items are popped from the end of the queue.
    /// Briefly: Items pushed first are popped first.
    case fifo
    
    /// When using the last in first out strategy, items are popped from the start of the queue.
    /// Briefly: Items pushed last are popped first.
    case lifo
}

/// This struct poses as a configuration bag for all of Pillarbox' configurable parameters.
public struct PillarboxConfiguration {
    
    /// The queuing strategy to use
    public var strategy: PillarboxQueueStrategy = .fifo
    
    public init(strategy: PillarboxQueueStrategy = .fifo) {
        self.strategy = strategy
    }
}

/// A object-based queue which is persisted to the disk. Supports both FIFO and LIFO strategies. Should be thread-safe as well.
public class Pillarbox<Element: Codable> {
    
    /// The lock used for synchronizing access to the underlying data structures.
    @usableFromInline
    var lock = pthread_rwlock_t()
    
    /// The cache used for persisting both the queue as well as the queued elements to disk.
    @usableFromInline
    let cache: Cache
    
    /// The queue used for keeping track of the element's keys
    @usableFromInline
    var queue: Queue<String>!
    
    /// The configuration which the Pillarbox was initialized with
    @usableFromInline
    let configuration: PillarboxConfiguration
    
    // MARK: - Creating a Pillarbox
    
    /// Initializes and returns a newly allocated Pillarbox.
    ///
    /// - Parameters:
    ///   - name: The name of the queue file
    ///   - url: The url of the directory to create the queue file in
    ///   - configuration: The Pillarbox configuration
    @inlinable
    public init(
        name: String,
        url: URL,
        configuration: PillarboxConfiguration = PillarboxConfiguration()
    ) {
        self.configuration = configuration
        self.cache = Cache(name: name, url: url)
        self.queue = self.setupQueue()
        
        // Init the rw lock alongside the class init.
        pthread_rwlock_init(&lock, nil)
    }
    
    deinit {
        // Destroy the rw lock alongside the class deinit.
        pthread_rwlock_destroy(&lock)
    }
    
    @usableFromInline
    func setupQueue() -> Queue<String> {
        // When let reading fail silently and just return
        // a new queue since - what are the options?
        let queue = readQueue() ?? Queue<String>()
        queue.strategy = configuration.strategy
        writeQueue(queue: queue)
        return queue
    }
    
    @usableFromInline
    func readQueue() -> Queue<String>? {
        cache["_queue"]
    }
    
    @usableFromInline
    func writeQueue(queue: Queue<String>) {
        cache["_queue"] = queue
    }
}

// MARK: - Performing Queue Operations

public extension Pillarbox {
    
    /// Retrieves, but does not remove, the head of the queue, or returns `nil`
    /// f the queue is empty. If the strategy is `fifo`, the first inserted item will
    /// be returned, for `lifo` it will be the last one.
    ///
    /// - Returns: The retrieved element or `nil`
    @inlinable
    func peek() -> Element? {
        // Lock for reading
        lockRead()
        // Be sure to unlock as we leave the function,
        // no matter at which point.
        defer { unlock() }
        
        for i in 0... {
            // Get the key of the topmost item.
            // If there is none, nil is returned.
            guard let key = queue.peek(offset: i) else { return nil }
            // Get the element from the cache by key. If no
            // element was found for the popped key, continue
            // with the next loop.
            guard let element: Element = cache[key] else { continue }
            // If an element was found for the key, return it.
            return element
        }
        
        return nil
    }
    
    /// Retrieves and removes the head of the queue, or returns `nil`
    /// if the queue is empty. Writes the updated queue to the disk and
    /// removes the persisted element. If the strategy is `fifo`, the first
    /// inserted item will be returned, for `lifo` it will be the last one.
    ///
    /// - Returns: The retrieved element or `nil`
    @inlinable
    @discardableResult
    func pop() -> Element? {
        // Lock for writing
        lockWrite()
        // Be sure to unlock as we leave the function,
        // no matter at which point.
        defer { unlock() }
        // Pop keys in a loop, as elements for popped keys
        // could be already expired. Therefore, we're popping
        // until we hit a key with a valid element, or no keys
        // are left in the queue.
        while true {
            // Pop the topmost key off the queue.
            // If there is none, nil is returned.
            guard let key = queue.pop() else { return nil }
            // Persist the updated queue to disk.
            writeQueue(queue: queue)
            // Pull the element from the cache. This removes the
            // data from the disk after successful retrieval. If
            // no element was found for the popped key, continue
            // with the next loop.
            guard let element: Element = cache.pull(forKey: key) else { continue }
            // If an element was found for the key, return it.
            return element
        }
    }
    
    /// Pushes the specified element into the queue and persist it on the disk.
    ///
    /// - Parameter element: The element to push into the queue.
    @inlinable
    func push(_ element: Element) {
        // Generate a random element identifier
        let key = UUID().uuidString
        // Lock for writing
        lockWrite()
        // Be sure to unlock as we leave the function
        defer { unlock() }
        // Store the element to the disk
        cache[key] = element
        // Push the identifier to the queue
        queue.push(key)
        // Persist the updated queue to disk
        writeQueue(queue: queue)
    }
    
    /// A Boolean value indicating whether the queue is empty.
    @inlinable
    var isEmpty: Bool {
        // Lock for read
        lockRead()
        // Be sure to unlock as we leave the function
        defer { unlock() }
        // Return result
        return queue.isEmpty
    }
    
    /// The number of elements in the queue.
    @inlinable
    var count: Int {
        // Lock for read
        lockRead()
        // Be sure to unlock as we leave the function
        defer { unlock() }
        // Return result
        return queue.count
    }
}


// MARK: - Lock Management

extension Pillarbox {
    
    @usableFromInline
    func lockWrite() {
        pthread_rwlock_wrlock(&lock)
    }
    
    @usableFromInline
    func lockRead() {
        pthread_rwlock_rdlock(&lock)
    }
    
    @usableFromInline
    func unlock() {
        pthread_rwlock_unlock(&lock)
    }
}
