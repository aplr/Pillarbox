import XCTest
@testable import Pillarbox

final class PillarboxTests: XCTestCase {
    
    func createPillarbox(
        named name: String = UUID().uuidString,
        strategy: PillarboxQueueStrategy = .fifo
    ) -> Pillarbox<String> {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let configuration = PillarboxConfiguration(strategy: strategy)
        
        return Pillarbox<String>(name: name, url: url, configuration: configuration)
    }
    
    func testInitPillarbox() {
        XCTAssertNoThrow(createPillarbox())
    }
    
    func testInitFromPersistedPillarbox() {
        let name = UUID().uuidString
        
        // Arrange: Create a new pillarbox and
        // populate it with test data.
        var pillarbox = createPillarbox(named: name)
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
        let pillarbox = createPillarbox(strategy: .fifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.pop()
        
        // Assert
        XCTAssertEqual(result, "One")
    }
    
    func testPopLifo() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .lifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.pop()
        
        // Assert
        XCTAssertEqual(result, "Two")
    }
    
    func testPopEmpty() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .lifo)
        
        // Act
        let result = pillarbox.pop()
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testPeekFifo() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .fifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.peek()
        
        // Assert
        XCTAssertEqual(result, "One")
    }
    
    func testPeekLifo() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .lifo)
        pillarbox.push("One")
        pillarbox.push("Two")
        
        // Act
        let result = pillarbox.peek()
        
        // Assert
        XCTAssertEqual(result, "Two")
    }
    
    func testPeekIdempotent() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .fifo)
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
        let pillarbox = createPillarbox(strategy: .fifo)
        
        // Act
        let result = pillarbox.peek()
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testIsEmptyWhenEmpty() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .fifo)
        
        // Act
        let result = pillarbox.isEmpty
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func testIsEmptyWhenNotEmpty() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .fifo)
        pillarbox.push("Hello")
        
        // Act
        let result = pillarbox.isEmpty
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func testCountWhenEmpty() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .fifo)
        
        // Act
        let result = pillarbox.count
        
        // Assert
        XCTAssertEqual(result, 0)
    }
    
    func testCountWhenNotEmpty() {
        // Arrange
        let pillarbox = createPillarbox(strategy: .fifo)
        pillarbox.push("Hello")
        
        // Act
        let result = pillarbox.count
        
        // Assert
        XCTAssertEqual(result, 1)
    }
}
