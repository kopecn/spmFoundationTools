import Foundation
import Testing

@testable import FoundationTransactions

// MARK: - Test Command

private struct TimeoutTestCommand: TransactionalCommand {
    var commandString: String = "noop"
    var arguments: [String] = []
    var timeout: Float?
    var trID: Int = -1
    var commandType: TransactionConcurrency = .parallel
}

// MARK: - F3: Structured Transaction Timeout

/// Regression coverage for F3: the `TransactionHandler` timeout must be a
/// structured, cancellable child `Task` (not a fire-and-forget
/// `DispatchQueue.global().asyncAfter`) so it cooperates with completion and
/// cancellation instead of outliving the transaction.
@Suite("TransactionHandler timeout")
struct TransactionHandlerTimeoutTests {

    @Test("testF3_completedTransactionNeverTimesOut")
    func testF3_completedTransactionNeverTimesOut() async {
        let handler = TransactionHandler<TimeoutTestCommand>(resourceID: "r1", initialState: .idle)
        let transaction = handler.submit(TimeoutTestCommand(), timeout: 0.15)

        handler.processResponse(transactionID: transaction.id, response: "ok")

        // Wait well past the timeout deadline; a lingering fire-and-forget
        // timer would flip the state to `.timedOut` here.
        try? await Task.sleep(for: .seconds(0.35))

        #expect(transaction.state == .completed)
    }

    @Test("testF3_incompleteTransactionTimesOutOnce")
    func testF3_incompleteTransactionTimesOutOnce() async {
        let handler = TransactionHandler<TimeoutTestCommand>(resourceID: "r2", initialState: .idle)
        let transaction = handler.submit(TimeoutTestCommand(), timeout: 0.1)

        try? await Task.sleep(for: .seconds(0.3))

        #expect(transaction.state == .timedOut)
    }

    @Test("testF3_cancelledTransactionNeverTimesOutLate")
    func testF3_cancelledTransactionNeverTimesOutLate() async {
        let handler = TransactionHandler<TimeoutTestCommand>(resourceID: "r3", initialState: .idle)
        let transaction = handler.submit(TimeoutTestCommand(), timeout: 0.1)

        handler.cancel(transactionID: transaction.id)

        // Wait well past the original timeout deadline; the pending timeout
        // task must have been cancelled and must not overwrite the state.
        try? await Task.sleep(for: .seconds(0.3))

        #expect(transaction.state == .cancelled)
    }
}
