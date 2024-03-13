import XCTest
@testable import Gate

final class GateTests: XCTestCase {
    func doBasicFunctionTest(concurrency: Int, detachedTasks: Bool) throws {
        let gate = Gate()

        do {
            let expectation = XCTestExpectation(description: "Tasks may enter a gate by default.")
            expectation.assertForOverFulfill = true
            expectation.expectedFulfillmentCount = concurrency

            let operation: @Sendable () async -> Void = {
                try! await gate.enter()
                expectation.fulfill()
            }

            for _ in 0..<concurrency {
                if detachedTasks {
                    Task.detached(operation: operation)
                } else {
                    Task(operation: operation)
                }
            }

            wait(for: [expectation], timeout: 1.0)
        }

        gate.close()

        do {
            let waitExpectation = XCTestExpectation(description: "Tasks must wait when the gate is closed.")
            waitExpectation.isInverted = true

            let openedExpectation = XCTestExpectation(description: "Tasks must resume when the gate is opened.")
            openedExpectation.assertForOverFulfill = true
            openedExpectation.expectedFulfillmentCount = concurrency

            let operation: @Sendable () async -> Void = {
                try! await gate.enter()
                waitExpectation.fulfill()
                openedExpectation.fulfill()
            }

            for _ in 0..<concurrency {
                if detachedTasks {
                    Task.detached(operation: operation)
                } else {
                    Task(operation: operation)
                }
            }

            wait(for: [waitExpectation], timeout: 2.0)

            gate.open()

            wait(for: [openedExpectation], timeout: 1.0)
        }
    }

    func doCancellationTest(concurrency: Int, detachedTasks: Bool) throws {
        let gate = Gate(initiallyOpen: false)

        let waitExpectation = XCTestExpectation(description: "Tasks must wait when the gate is closed.")
        waitExpectation.isInverted = true

        let passedThroughExpectation = XCTestExpectation(description: "Tasks must resume when the gate is opened.")
        passedThroughExpectation.assertForOverFulfill = true
        passedThroughExpectation.expectedFulfillmentCount = 1 < concurrency ? concurrency / 2 : 1
        passedThroughExpectation.isInverted = 1 >= concurrency

        let cancelledExpectation = XCTestExpectation(description: "Tasks should stop waiting on the gate immediately if they are cancelled.")
        cancelledExpectation.assertForOverFulfill = true
        cancelledExpectation.expectedFulfillmentCount = (concurrency + 1) / 2

        let operation: @Sendable () async throws -> Void = {
            do {
                do {
                    try await gate.enter()
                } catch is CancellationError {
                    cancelledExpectation.fulfill()
                    return
                }

                passedThroughExpectation.fulfill()
            } catch {
                waitExpectation.fulfill()
            }
        }

        var tasksToCancel = [Task<Void, any Error>]()

        for i in 0..<concurrency {
            let task: Task<Void, any Error>

            if detachedTasks {
                task = Task.detached(operation: operation)
            } else {
                task = Task(operation: operation)
            }

            if i % 2 == 0 {
                tasksToCancel.append(task)
            }
        }

        wait(for: [waitExpectation], timeout: 2.0)

        for task in tasksToCancel {
            task.cancel()
        }

        wait(for: [cancelledExpectation], timeout: 1.0)

        gate.open()

        wait(for: [passedThroughExpectation], timeout: 1.0)
    }

    func testGateWithinSingleIsolationDomain() throws {
        for i in [1, 10, 100] {
            try doBasicFunctionTest(concurrency: i, detachedTasks: false)
            try doCancellationTest(concurrency: i, detachedTasks: false)
        }
    }

    func testGateAcrossIsolationDomains() throws {
        for i in [1, 10, 100] {
            try doBasicFunctionTest(concurrency: i, detachedTasks: true)
            try doCancellationTest(concurrency: i, detachedTasks: true)
        }
    }

    func testClosedGateEnteredByAlreadyCancelledTask() throws {
        let gate = Gate(initiallyOpen: false)

        let passedThroughExpectation = XCTestExpectation(description: "Task should not have passed through the gate.")
        passedThroughExpectation.isInverted = true

        let cancelledExpectation = XCTestExpectation(description: "Task should have been cancelled.")

        Task {
            withUnsafeCurrentTask {
                $0!.cancel()
            }

            do {
                try await gate.enter()
            } catch is CancellationError {
                cancelledExpectation.fulfill()
                return
            }

            passedThroughExpectation.fulfill()
        }

        wait(for: [cancelledExpectation, passedThroughExpectation], timeout: 1.0)

        gate.open() // Just to ensure that opening the gate afterwards doesn't somehow crash.
    }
}
