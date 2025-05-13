import Foundation
import PlaygroundSupport

// Keep playground running for asynchronous operations
PlaygroundPage.current.needsIndefiniteExecution = true

/**
# SimpleDispatch
 
 A standalone Swift playground project to demonstrate simple examples for:
 
 - Dispatch queues
 - Basic GCD (Grand Central Dispatch) queue
 
 # IMPORTANT #############
 # This playground handles background queues,
 # there is a chance that this playground may stall
 # or hang.
 #########################
 
 # Examples:
 - Example 1 - Basic Async
 - Example 2 - Fetch with async
 - Example 3 - Simple GCD example
*/

// MARK: Quick `async` vs `sync` discussion

/// Use `sync` when:
/// [x] We want to guarantee completion before continuing
/// [x] The task is critical, and must be done before we continue
///
///  We should be careful not to dispatch to main queue from another queue - it will cause deadlock

/// Use `async` when:
/// [x] The work can happen in the background
/// [x] The UI should remain responsive whilst we are wiating for response
/// [x] The task is long-running
///
/// Practically, async is more safer and better suited for most app use cases.


// Create a DispatchGroup to track all the async work
let dispatchGroup = DispatchGroup()

// Use a startTime: for tracking how long things take
let startTime = Date()

print ("** Started at: \(startTime) **")

// -----

// MARK: Mock Data

struct Product: @unchecked Sendable {
    let id: Int
    let name: String
    let price: Double
    let inStock: Bool
}

/// A class to handle products
final class ProductManager: Sendable {
    /// Create a simple list of products
    let products: [Product] = [
        Product(id: 1, name: "iPhone", price: 999.0, inStock: true),
        Product(id: 2, name: "MacBook", price: 1299.0, inStock: true),
        Product(id: 3, name: "AirPods", price: 179.0, inStock: false),
        Product(id: 4, name: "iPad", price: 499.0, inStock: true),
        Product(id: 5, name: "Apple Watch", price: 399.0, inStock: false),
    ]

    /// Simulate fetching products with a short delay
    /// Use a closure and return after completing
    ///
    /// The @sendable attribute is part of Swift's concurrency safety system that was introduced with Swift 5.5. It ensures that closures passed to asynchronous contexts don't capture mutable state in an unsafe way.
    ///
    func fetchAllProducts(completion:@escaping @Sendable ([Product]) -> Void) {
        print ("Fetching all products...")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
            print ("    completed, returning closure")
            completion(self.products)
        })
    }
    
    func fetchProduct(byId id: Int, completion:@escaping @Sendable (Product?) -> Void) {
        print ("Fetching a single product from id: \(id)...")
        
        /// Find first product that matches the ID provided
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
            let product = self.products.first { return $0.id == id }
            print ("    completed, returning closure")
            completion(product)
        })
    }
    
    /// Simulate processing products applying a discount
    /// Returns a collection of results with calculated discounts
    func processProductDiscounts(on products:[Product]) -> [(product: Product, discount: Double)] {
        
        return products.map { product in
            var discountAmount: Double
            if product.inStock {
                discountAmount = 0.1
            }
            else {
                discountAmount = 0.0
            }
            let discount = (product.price * discountAmount)
            return (product, discount)
        }
    }
}

/// Create product manager object
var productManager = ProductManager()

// ---

// MARK: Dispatch - Quick examples

///  Dispatch queue is used to manage execution of tasks, either concurrently or serial
///   and uses a FIFO (First in, first out) list.
///
/// # Understanding two use cases of dispatch types:
/// `.main`:
/// Use case: it's used mainily for UI tasks, attenots to synchronously execute a work item
/// `.global`:
/// Use case: mostly used for long-running tasks, like a network call
///
/// # Differences
/// The main difference is their prioritisation of execution tasks on the queue,
///
///  `.background` has the lowest priority
///  `.userInitiated` and `.userInteractive` have the highest priority

// ---

// MARK: Example 1 - Basic Async
print ("Example #1: Basic Async Dispatch")
print ("\n--------------------\n")

dispatchGroup.enter()

/// Delayed Execution with `asyncAfter`
/// Schedules a work item for execution at the specified time, and returns immediately.
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
    print ("  asyncAfter: Inside the queue...\n")
    let currentTime = Date()
    let elasped = currentTime.timeIntervalSince(startTime)
    let formattedOutput = String(format: "%.2f", elasped)
    print ("> Main queue executed after: \(formattedOutput) seconds")
    print("   Thread: \(Thread.current)")
    
    dispatchGroup.leave() // Task is complete
})



/// Use a custom queue label, delay after 1 second
dispatchGroup.enter()

let myCustomQueue = DispatchQueue(label: "com.example.mycustomQueue")
print("Custom queue: Scheduling work after 1 second...")
myCustomQueue.asyncAfter(deadline: .now() + 1.0) {
    let currentTime = Date()
    let elapsed = currentTime.timeIntervalSince(startTime)
    print("> Custom queue work executed after \(String(format: "%.2f", elapsed)) seconds")
    print("   Thread: \(Thread.current)")
    dispatchGroup.leave()
}

// MARK: Example 2 - Fetch with async

print ("Example #2: Fetch with async")
print ("\n--------------------\n")

dispatchGroup.enter()
DispatchQueue.global(qos: .userInitiated).async {
    print("Background thread starting work on: \(Thread.current)")

    productManager.fetchAllProducts { products in
        print("Got: \(products.count) products")
        
        // Process product discounts in the background
        let discountedProducts = productManager.processProductDiscounts(on: products)
        print("- Processing product discounts in background -")
        
        /// Go back to the main thread
        DispatchQueue.main.async {
            print ("On thread: \(Thread.current)")
            
            print ("\nProduct discounts:")
            
            for (product, discount) in discountedProducts {
                let formattedDiscount = String(format: "%.2f", discount)
                let discountString = ("Discount: £\(formattedDiscount)")
                print ("    - \(product.name) : £\(product.price) - \(discountString)")
            }
            
            dispatchGroup.leave()
        }
        
        print("[X] Async Completed\n")
    }
}

// --

// MARK: Example 3 - GCD examples


// --

print("\n>> Main thread continues without waiting <<\n")

print ("\n--------------------\n")

// MARK: Exit playground

/// Use notify to let us know when all dispatch work is done
dispatchGroup.notify(queue: .main) {
    let currentTime = Date()
    let elaspedTime = currentTime.timeIntervalSince(startTime)
    let formattedTime = String(format: "%.2f", elaspedTime)
    print ("\n>> All tasks completed after \(formattedTime) seconds <<")
    
    print("\n\n-- Exiting Playground -- ")
    PlaygroundPage.current.finishExecution()
}
