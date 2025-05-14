import Foundation
import PlaygroundSupport

/**
 # ErrorHandlingDemo
 
 A standalone Swift playground demo to demonstrate simple examples for:
 
 - Demo #1 - Simple do-try-catch
 - Demo #2 - More complex do-try-catch
 - Demo #3 - Result tuple
 
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
    public var isLocked: Bool = false // used in demo #2
    
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

// MARK: - Demo #1 - Simple do-try-catch


print ("\nDemo #1 - Do-try-catch block")
print ("\n--------------------\n")

enum TransactionType {
    case credit, debit
}

func performDemo_transaction(transactionType: TransactionType, amount: Int, wallet: Wallet) {
    var wallet = wallet
    do {
        switch transactionType {
        case .credit:
            try wallet.credit(amount)
        case .debit:
            try wallet.debit(amount)
        }
    } catch let err {
        print ("\n Error -- \(err.localizedDescription)")
    }
}



let deposit: Int = 100
var wallet = Wallet(deposit: deposit)

performDemo_transaction(transactionType: .credit, amount: 50, wallet: wallet) // will succeed
performDemo_transaction(transactionType: .credit, amount: -50, wallet: wallet) // will throw
performDemo_transaction(transactionType: .credit, amount: 0, wallet: wallet) // will throw
performDemo_transaction(transactionType: .debit, amount: 10, wallet: wallet) // will succeed
performDemo_transaction(transactionType: .debit, amount: -10, wallet: wallet) // will throw
performDemo_transaction(transactionType: .debit, amount: -10, wallet: wallet) // will throw
performDemo_transaction(transactionType: .debit, amount: 0, wallet: wallet) // will throw

print ("\n Balance: \(wallet.balance)")



// MARK: - Demo #2 - More complex do-try-catch

print ("\nDemo #2 - More complex do-try-catch block")
print ("\n--------------------\n")

/// Extend the wallet to do a more complex demo of do-try-catch

enum WalletError: Error {
    case walletLocked
    case exceededDailyLimit(limit: Int, attempted: Int)
    case suspiciousActivity(reason: String)
    case transactionTimedOut
}

extension WalletError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .walletLocked: return NSLocalizedString("Wallet is locked", comment: "Wallet error")
        case .exceededDailyLimit(let limit, let attempted): return NSLocalizedString("Your daily limit of \(limit) is exceeded. Attempted \(attempted)", comment: "Wallet error")
        case .suspiciousActivity(let reason): return NSLocalizedString("Flagged for suspicious activity: \(reason)", comment: "Wallet error")
        case .transactionTimedOut: return NSLocalizedString("Transaction timed out", comment: "Wallet error")
        }
    }
}

func processAdvancedTransaction(wallet: inout Wallet, creditAmount: Int?) throws -> Int {
    guard !wallet.isLocked else {
        throw WalletError.walletLocked
    }
    
    // Validate the optional parameter amount
    guard let amount = creditAmount, amount > 0 else {
       throw NumericErrorDelegate.mustBePositive
    }
    
    return 0
}



// MARK: - Demo #3 - Result tuple

print ("\nDemo #3 - Use a result tuple")
print ("\n--------------------\n")

/// Define a typealias for our result tuple
typealias TransactionResult = (success: Bool, balance: Int?, error: Error?)

/// Extend the wallet with result tuples
extension Wallet {
    mutating func performTransaction(credit amount: Int) -> TransactionResult {
        do {
            try self.credit(amount)
            return (true, self.balance, nil)
        }
        catch {
            return (false, nil, error)
        }
    }
    
    // Takes an optional amount with smart defaults
    mutating func performSafeCredit(amount: Int?) -> TransactionResult {
        let safeAmount = amount ?? 10
        guard safeAmount > 0 else {
            return (false, nil, NumericErrorDelegate.mustBePositive)
        }
        
        // process transaction
        do {
            try self.credit(safeAmount)
            return (true, self.balance, nil)
        } catch {
            return (false, self.balance, error)
        }
    }
}

var resultWallet = Wallet(deposit: 100)

/// This should succeed
let result1 = resultWallet.performTransaction(credit: 50)

if result1.success, let balance = result1.balance {
    print("Transaction successful! New balance: \(balance)")
} else if let error = result1.error {
    print("Transaction failed: \(error.localizedDescription)")
}

/// This should fail
let result2 = resultWallet.performTransaction(credit: -25)
if result2.success, let balance = result2.balance {
    print("Transaction successful! New balance: \(balance)")
} else if let error = result2.error {
    print("Transaction failed: \(error.localizedDescription)")
}

/// Try with nil value, using a default value
let result3 = resultWallet.performSafeCredit(amount: nil)
if result3.success {
    print("Default transaction successful! Balance: \(result3.balance ?? 0)")
}

print ("\n--------------------\n")

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()
