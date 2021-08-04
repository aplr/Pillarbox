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

/// A class of types whose instances hold the value of an entity with stable identity.
public protocol QueueIdentifiable {
    
    /// The stable identity of the entity associated with this instance.
    var id: String { get }

}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Identifiable where Self: QueueIdentifiable, ID == String {}

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
    
    @usableFromInline
    func identifier(for element: Element) -> String {
        guard let identifiable = element as? QueueIdentifiable else {
            return UUID().uuidString
        }
        
        return identifiable.id
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
    /// - Returns: The key which identifies the element
    @inlinable
    @discardableResult
    func push(_ element: Element) -> String {
        // Generate a random element identifier
        let key = identifier(for: element)
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
        // Return the key
        return key
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


// MARK: - Access and Manipulate Queue Data


public extension Pillarbox {
    
    /// All elements in the queue
    @inlinable
    var elements: [Element] {
        // Lock for read
        lockRead()
        // Be sure to unlock as we leave the function
        defer { unlock() }
        // Return result
        return queue.elements.compactMap({ cache[$0] })
    }
    
    /// Updates the specified element in the queue with the given key.
    ///
    /// - Parameters:
    ///   - element: The element to update
    ///   - key: The cache key representing the element
    @inlinable
    func update(_ element: Element, for key: String) {
        // Lock for reading
        lockRead()
        // Return early if no element with the given key exists
        guard let _: Element = cache[key] else { return }
        // Unlock after we determined if the key exists
        unlock()
        // Update the element
        put(element, for: key)
    }
    
    /// Puts the specified element in the queue with the given key.
    ///
    /// - Parameters:
    ///   - element: The element to put
    ///   - key: The cache key representing the element
    @inlinable
    func put(_ element: Element, for key: String) {
        // Don't set the element if the key does not match
        guard let identifiable = element as? QueueIdentifiable, identifiable.id == key else { return }
        // Lock for writing
        lockWrite()
        // Be sure to unlock as we leave the function
        defer { unlock() }
        // Push the element to the queue if it does not exist yet
        if (cache[key] as Element?) == nil { queue.push(key) }
        // Store the element to the disk
        cache[key] = element
    }
    
    /// Removes the element identified by the given key.
    ///
    /// - Parameter key: The key of the element to remove
    @inlinable
    func remove(key: String) {
        // Lock for writing
        lockWrite()
        // Be sure to unlock as we leave the function
        defer { unlock() }
        // Remove the key from the queue
        queue.remove(key)
        // Remove the element from the cache
        cache.remove(forKey: key)
    }
    
    @inlinable
    subscript(key: String) -> Element? {
        get {
            return cache[key]
        } set {
            guard let newValue = newValue else { return }
            self.update(newValue, for: key)
        }
    }
}


// MARK: - Performing Queue Operations

public extension Pillarbox where Element: QueueIdentifiable {
    
    /// Updates the specified identifiable element in the queue
    ///
    /// - Parameter element: The element to update
    @inlinable
    func update(_ element: Element) {
        self.update(element, for: element.id)
    }
    
    /// Puts the specified identifiable element into the queue
    ///
    /// - Parameter element: The element to put
    @inlinable
    func put(_ element: Element) {
        self.put(element, for: element.id)
    }
    
    /// Removes the element from the queue.
    ///
    /// - Parameter element: The element to remove
    @inlinable
    func remove(_ element: Element) {
        self.remove(key: element.id)
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
