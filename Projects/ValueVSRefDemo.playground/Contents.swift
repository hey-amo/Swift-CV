import Foundation
import PlaygroundSupport

/**
# ValueVSRefDemo
 
 A standalone Swift playground project to demonstrate simple examples for:
  - structs verses classes
 
 */

/// This is a value type
struct EmployeeAsStruct: Identifiable, Hashable, Equatable {
    let id: UUID = UUID()
    var name: String
    var salary: Double
}

extension EmployeeAsStruct : CustomStringConvertible {
    var description: String {
        return " id: \(id), name: \(name), $\(salary)"
    }
}

/// This is a reference type
class EmployeeAsClass: Identifiable, Hashable, Equatable {
    let id: UUID = UUID()
    var name: String
    var salary: Double
    
    init(name: String, salary: Double) {
        self.name = name
        self.salary = salary
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformaance
    static func == (lhs: EmployeeAsClass, rhs: EmployeeAsClass) -> Bool {
        return (lhs.id == rhs.id)
    }
}

extension EmployeeAsClass : CustomStringConvertible {
    var description: String {
        return " id: \(id), name: \(name), $\(salary)"
    }
}

/// A value type means that each time we manipulate it, we create a new version
/// A value type is for records, one-offs, things that don't have behaviour
///
/// A class means that if we manipulate it somewhere else, we update the original version.
/// A class is for objects, where we expect behaviour, or want one update to maintain
/// This is especially true if we have parent objects that update child objects

var emp1 = EmployeeAsStruct(name: "Alex", salary: Double(120_000))

print ("# Demo #1 - Simple Struct example (value type)\n")

print ( "employee -- \(emp1)\n")
emp1.salary = Double(60_000)
print ( "employee -- \(emp1)\n")

print ("\n--------------------\n")


print ("# Demo #2 - Simple Class example (reference type)\n")

var emp2 = EmployeeAsClass(name: "Sarah", salary: Double(120_000))
print ( "employee -- \(emp2)\n")
emp2.salary = Double(45_000)
print ( "employee -- \(emp2)\n")

print ("\n--------------------\n")

 print("\n\n-- Exiting Playground -- ")
 PlaygroundPage.current.finishExecution()


