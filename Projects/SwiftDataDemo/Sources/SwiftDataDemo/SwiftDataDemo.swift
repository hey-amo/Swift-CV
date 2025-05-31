/*
 # SwiftDataDemo
 
 A simple standalone Swift playground project to demonstrate:
 
 - SwiftData
 
 ## Usage
 
 - Run the XCTest `SwiftDataDemoTests`
 - All output is console logged.
 
 ## Notes
 
 - Running in Swift 6 mode - some Sendable warnings may appear
 - Demo is quite limited, due to SwiftData compatibility issues
 
 */

#if compiler(>=6.0)
#warning("Running in Swift 6 mode - some Sendable warnings may appear")
#endif

@preconcurrency import SwiftData
import Foundation

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

// -----------------

@MainActor
func runDemos() {
    let context = container.mainContext

    createExpenses(context: context)
    
    print("\n--------------------\n")
    
    // Read demo
    /// Get all expenses, sorted by highest first
    readExpenses(context: context)
          
    print("\n--------------------\n")
    
    // Update demo
    /// Update the car's value to 15K
    updateExpense(context: context, name: "Car", newValue: 15_000)
        
    print("\n--------------------\n")
        
    // Delete demo
    /// Delete golf clubs
    deleteExpense(context: context, name: "Golf clubs")
        
    print("\n--------------------\n")
        
    // Simple search demo
    /// Find all expenses >= 10K
    searchExpenses(context: context, minValue: 10_000)
        
    print("\n--------------------\n")
    print("-- Demos Complete --")
}


// MARK: Functions


// Create
@MainActor
func createExpenses(context: ModelContext) {
    
    // Create demo
    let date = Date()
    let expenses: [Expense] = [
        Expense(name: "Car", date: date, value: 12_000),
        Expense(name: "House", date: date, value: 120_000),
        Expense(name: "Golf clubs", date: date, value: 500),
        Expense(name: "Laptop", date: date, value: 2_500),
        Expense(name: "Holiday", date: date, value: 8_000),
    ]
    
        for expenseModel in expenses {
            context.insert(expenseModel)
        }
        
        do {
            try context.save()
            print("✅ Created \(expenses.count) expenses successfully")
        } catch {
            print ("[X] - Error: \(error) -")
        }
    
}

// Read
@MainActor
func readExpenses(context: ModelContext) {
    print(">> READ: All expenses sorted by highest value")
    do {
        let fetchDescriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.value, order: .reverse)]
        )
        let allExpenses = try context.fetch(fetchDescriptor)

        for (index, expense) in allExpenses.enumerated() {
            print("\(index + 1). \(expense.name): $\(String(format: "%.2f", expense.value))")
        }
    } catch {
        print("[x] Error reading expenses: \(error)")
    }
}

// Update
@MainActor
func updateExpense(context: ModelContext, name: String, newValue: Double) {
    print(">> UPDATE: Updating \(name) value to $\(String(format: "%.2f", newValue))")
    do {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.name == name }
        )
        let expenses = try context.fetch(fetchDescriptor)
        
        if let expense = expenses.first {
            expense.value = newValue
            try context.save()
            print("✅ Updated \(expense.name) successfully")
        } else {
            print("[X] Expense '\(name)' not found")
        }
    } catch {
        print("[X] Error updating expense: \(error)")
    }
}

// Delete demo
@MainActor
func deleteExpense(context: ModelContext, name: String) {
    print(">> DELETE: Removing \(name)")
    do {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.name == name }
        )
        let expenses = try context.fetch(fetchDescriptor)
        
        if let expense = expenses.first {
            context.delete(expense)
            try context.save()
            print("✅ Deleted \(expense.name) successfully")
        } else {
            print("[X] Expense '\(name)' not found")
        }
    } catch {
        print("[X] Error deleting expense: \(error)")
    }
}

// Search demo

@MainActor
func searchExpenses(context: ModelContext, minValue: Double) {
    print("🔍 SEARCH: Expenses over $\(String(format: "%.2f", minValue))")
    do {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.value >= minValue },
            sortBy: [SortDescriptor(\.value, order: .reverse)]
        )
        let filteredExpenses = try context.fetch(fetchDescriptor)
        
        for expense in filteredExpenses {
            print("• \(expense.name): $\(String(format: "%.2f", expense.value))")
        }
        
        if filteredExpenses.isEmpty {
            print("No expenses found over $\(String(format: "%.2f", minValue))")
        }
    } catch {
        print("[X] Error searching expenses: \(error)")
    }
}

// ----------

public func runSwiftDataDemo() async {
    await runDemos()
}
