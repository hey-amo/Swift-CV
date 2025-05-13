import Foundation
import PlaygroundSupport

/**
 # ErrorHandlingDemo
 
 A standalone Swift playground demo to demonstrate simple examples for:
 
 - do-try-catch-throw blocks
 - custom error handling
 - returning a result tuple
 
 This demo: Adding, subtracting funds from a `Wallet` with custom error handling, throwing, etc
 */

/// Setup custom errors for handling numeric errors
enum NumericErrorDelegate: Error {
    case mustBePositive
    case notEnoughFunds(funds: Int)
}

/// Setup custom error localised errors
extension NumericErrorDelegate : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .mustBePositive:
            return NSLocalizedString("Must be a positive number", comment: "Numeric error: Must be a positive number")
            
        case .notEnoughFunds(let funds):
            NSLog("Funds: \(funds)")
            return NSLocalizedString("Funds: \(funds)  - You do not have enough funds", comment: "Numeric error: Not enough to do action")
        }
    }
}

struct Wallet {
    private var _coins: Int
    
    public init(with amount: Int = 0) {
        self._coins = amount
    }
    
    public var balance: Int {
        return self._coins
    }
}


print ("\n--------------------\n")

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()
