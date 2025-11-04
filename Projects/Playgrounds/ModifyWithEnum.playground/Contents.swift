/** 
Modify a struct using enums
- Credit, debit funds (integer) from a `Wallet`
*/

import Foundation

enum Transaction {
    case credit(amount: Int)
    case debit(amount: Int)
}

struct Wallet {
    let cash: Int
    
    func execute(_ transaction: Transaction) -> Self {
        switch transaction {
        case .credit(let amount):
            let balance = amount + cash
            return .init(cash: balance)
        case .debit(let amount):
            let balance = amount - cash
            return .init(cash: balance)
        }
    }
}

var w = Wallet(cash: 100)
print (w.cash)
w = w.execute(.credit(amount: 100))
print (w.cash)
w = w.execute(.debit(amount: 50))
print (w.cash)
