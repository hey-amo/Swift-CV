import Foundation
/**
# Concurrency examples
 
 A standalone Swift playground project to demonstrate simple examples for:
 
 - Dispatch
 - Basic GCD (Grand Central Dispatch) queue
 - Async/Await
 - Task
 - MainActor
*/

// MARK: Mock Data

struct Product {
    let id: Int
    let name: String
    let price: Double
    let inStock: Bool
}

/// Create a simple list of products
let products: [Product] = [
    Product(id: 1, name: "iPhone", price: 999.0, inStock: true),
    Product(id: 2, name: "MacBook", price: 1299.0, inStock: true),
    Product(id: 3, name: "AirPods", price: 179.0, inStock: false),
    Product(id: 4, name: "iPad", price: 499.0, inStock: true),
    Product(id: 5, name: "Apple Watch", price: 399.0, inStock: false),
]

// MARK: Dispatch


