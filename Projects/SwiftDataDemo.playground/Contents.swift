/*
 # SwiftDataDemo
 
 A simple standalone Swift playground project to demonstrate:
 
 - SwiftData
 */

import SwiftData
import Foundation
import PlaygroundSupport


@Model
class Expense {
    @Attribute(.unique) var name: String
    var date: Date
    var value: Double
    
    init(name: String, date: Date, value: Double) {
        self.name = name
        self.date = date
        self.value = value
    }
}

let container: ModelContainer = {
    let schema = Schema([Expense.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    return container
}()

let context =  container.mainContext


// MARK: CRUD demo

// Create demo
let date = Date()
let expenses: [Expense] = [
    Expense(name: "Car", date: date, value: 12_000),
    Expense(name: "House", date: date, value: 120_000),
    Expense(name: "Golf clubs", date: date, value: 500),
]

for expenseModel in expenses {
    context.insert(expenseModel)
}

do {
    try context.save()
} catch {
    print (" - Error: \(error) -")
}


// Read demo
@Query(sort: \Expense.value) var expensesQuery:[Expense]

// Update demo

// Delete demo

// Search demo



print ("\n--------------------\n")

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()
