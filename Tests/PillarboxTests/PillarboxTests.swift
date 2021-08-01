import XCTest
@testable import Pillarbox

struct TestIdentifiable: QueueIdentifiable, Identifiable, Codable, Hashable {
    
    let id: String

}

final class PillarboxTests: XCTestCase {
    
    func createPillarbox<E>(
        named name: String = UUID().uuidString,
        strategy: PillarboxQueueStrategy = .fifo
    ) -> Pillarbox<E> {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let configuration = PillarboxConfiguration(strategy: strategy)
        
        return Pillarbox<E>(name: name, url: url, configuration: configuration)
    }
    
    func testInitPillarbox() {
        XCTAssertNoThrow(createPillarbox() as Pillarbox<String>)
    }
    
    func testInitFromPersistedPillarbox() {
        let name = UUID().uuidString
        
        // Arrange: Create a new pillarbox and
        // populate it with test data.
        var pillarbox: Pillarbox<String> = createPillarbox(named: name)
        pillarbox.push("Hello")
        pillarbox.push("World")
        
        // Act: Create a new pillarbox instance
        // which should load the persisted data.
        pillarbox = createPillarbox(named: name)
        
        // Assert: Check if the new pillarbox
        // instance did load the persisted data.
        XCTAssertEqual(pillarbox.pop(), "Hello")
        XCTAssertEqual(pillarbox.pop(), "World")
    }
    
    func testPopFifo() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.pop()
        
        // Assert
        XCTAssertEqual(result, "One")
    }
    
    func testPopLifo() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .lifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.pop()
        
        // Assert
        XCTAssertEqual(result, "Two")
    }
    
    func testPopEmpty() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .lifo)
        
        // Act
        let result = pillarbox.pop()
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testPeekFifo() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.peek()
        
        // Assert
        XCTAssertEqual(result, "One")
    }
    
    func testPeekLifo() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .lifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.peek()
        
        // Assert
        XCTAssertEqual(result, "Two")
    }
    
    func testPeekIdempotent() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result1 = pillarbox.peek()
        let result2 = pillarbox.peek()
        
        // Assert
        XCTAssertEqual(result1, "One")
        XCTAssertEqual(result2, "One")
    }
    
    func testPeekEmpty() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        
        // Act
        let result = pillarbox.peek()
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testIsEmptyWhenEmpty() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        
        // Act
        let result = pillarbox.isEmpty
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func testIsEmptyWhenNotEmpty() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        pillarbox.push("Hello")
        
        // Act
        let result = pillarbox.isEmpty
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func testCountWhenEmpty() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        
        // Act
        let result = pillarbox.count
        
        // Assert
        XCTAssertEqual(result, 0)
    }
    
    func testCountWhenNotEmpty() {
        // Arrange
        let pillarbox: Pillarbox<String> = createPillarbox(strategy: .fifo)
        pillarbox.push("Hello")
        
        // Act
        let result = pillarbox.count
        
        // Assert
        XCTAssertEqual(result, 1)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testIdentifiableConformsToQueueIdentifiable() {
        // Arrange
        let pillarbox: Pillarbox<TestIdentifiable> = createPillarbox(strategy: .fifo)
        let identifiable = TestIdentifiable(id: UUID().uuidString)
        pillarbox.push(identifiable)
        
        // Act
        let result = pillarbox[identifiable.id]
        
        // Assert
        XCTAssertEqual(result, identifiable)
    }
}
