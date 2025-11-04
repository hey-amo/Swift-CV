//
//  FactoryPattern.swift
//  Factory design pattern
//
//  Created by Amarjit on 21/10/2025.
//

import Foundation

// MARK: - Business Use Case: Payment Processing System

// An e-commerce platform needs to process payments through multiple methods:
// - (PayPal, Credit Card).
// The Factory pattern allows creating the right
// payment processor without exposing instantiation logic to the client.

/* Factory Pattern Benefits:
 ✓ Single responsibility - factory handles creation logic
 ✓ Open/Closed principle - easy to add new payment methods
 ✓ Client code doesn't need to know concrete classes
*/

public protocol PaymentProcessor {
    var processorName: String { get }
    func processPayment(amount: Double, currency: String) -> Bool
    func refund(transactionId: String, amount: Double) -> Bool
}

// This is a mock paypal processor
class PayPalProcessor: PaymentProcessor {
    let processorName = "PayPal"
    
    func processPayment(amount: Double, currency: String) -> Bool {
        print("🅿️  Processing \(currency)\(amount) via PayPal")
        print("   Redirecting to PayPal login...")
        print("   Authenticating user...")
        print("   ✅ Payment completed - Transaction ID: PP-\(Int.random(in: 10000...99999))")
        return true
    }
    
    func refund(transactionId: String, amount: Double) -> Bool {
        print("🅿️  Processing PayPal refund for \(transactionId)")
        return true
    }
}

// This is a mock cc processor
class CreditCardProcessor: PaymentProcessor {
    let processorName = "Credit Card"
    
    func processPayment(amount: Double, currency: String) -> Bool {
       print("💳 Processing \(currency)\(amount) via Credit Card")
       print("   Validating card details...")
       print("   Contacting payment gateway...")
       print("   ✅ Payment authorized - Transaction ID: CC-\(Int.random(in: 10000...99999))")
       return true
   }
    
    func refund(transactionId: String, amount: Double) -> Bool {
        print("💳 Refunding \(amount) to card for \(transactionId)")
        return true
    }
}

// MARK: - Factory

class PaymentProcessorFactory {
    enum PaymentMethod {
        case creditCard
        case paypal
    }
    
    static func createProcessor(for method: PaymentMethod) -> PaymentProcessor {
        switch method {
        case .creditCard:
            return CreditCardProcessor()
        case .paypal:
            return PayPalProcessor()
        }
    }
}

// MARK: - Client Code (Business Logic)

class OrderCheckoutService {
    public func processOrder(paymentMethod: PaymentProcessorFactory.PaymentMethod,
                     amount: Double,
                     currency: String = "$") {
        
        // Factory creates the appropriate payment processor
        let processor = PaymentProcessorFactory.createProcessor(for: paymentMethod)
        
        print("Selected payment method: \(processor.processorName)")
        print()
        
        let success = processor.processPayment(amount: amount, currency: currency)
        
        if success {
            print("\n🎉 Order completed successfully!")
        } else {
            print("\n❌ Payment failed. Please try again.")
        }
    }
}

public func runFactoryPatternDemo() {
    print("FACTORY PATTERN DEMO: Mock Payment Processing")

    let checkout = OrderCheckoutService()

    // Simulate 2 different customer purchases
    checkout.processOrder(paymentMethod: .creditCard, amount: 149.99)
    checkout.processOrder(paymentMethod: .paypal, amount: 89.50)
}
