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

/// Wallet model
struct Wallet {
    private var _coins: Int
    public var balance: Int {
        get { return self._coins }
    }
    
    init(deposit amount: Int = 0) {
        print ("Depositing: \(amount) into wallet")
        self._coins = amount
    }
    
    mutating func credit(_ amount: Int = 0) throws {
        guard amount > 0 else {
            throw NumericErrorDelegate.mustBePositive
        }
        
        handleCredit(amount)
    }
    
    mutating func debit(_ amount: Int = 0) throws {
        guard amount > 0 else {
            throw NumericErrorDelegate.mustBePositive
        }
        guard (_coins >= amount) else {
            throw NumericErrorDelegate.notEnoughFunds(funds: _coins)
        }
        guard ((_coins - amount) >= 0) else {
            throw NumericErrorDelegate.notEnoughFunds(funds: _coins)
        }
        
        handleDebit(amount)
    }
    
    private mutating func handleCredit(_ amount: Int) {
        print ("Credited: \(amount) into wallet")
        self._coins += amount
    }
    
    private mutating func handleDebit(_ amount: Int) {
        print ("Debited: \(amount) from wallet")
        self._coins -= amount
    }
}

print ("Demo #1 - Do-try-catch block")
print ("\n--------------------\n")

let deposit: Int = 100
var wallet = Wallet(deposit: deposit)

do {
    try wallet.credit(50)  // will succeed
    try wallet.credit(-100) // will throw
    try wallet.debit(-50) // will throw
    try wallet.credit(0) // will throw
    try wallet.debit(0) // will throw
    try wallet.debit(25)  // will succeed
} catch let err {
    print ("\n Error -- \(err.localizedDescription)")
}

print ("\n Balance: \(wallet.balance)")

print ("Demo #2 - More complex do-try-catch block")
print ("\n--------------------\n")


print ("Demo #3 - Use a result tuple")
print ("\n--------------------\n")


print ("\n--------------------\n")

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()
