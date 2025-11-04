import Foundation
import PlaygroundSupport

/**
# ValueVSRefDemo
 
 A standalone Swift playground project to demonstrate simple examples for:
  
 - structs verses classes

 Structs are value types
 Classes are reference types
 */

struct EmployeeStruct: CustomStringConvertible {
    var name: String
    var salary: Double
    var description: String { "name: \(name), salary: \(salary)" }
}

struct EmployeeClass: CustomStringConvertible {
    var name: String
    var salary: Double
    init(name: String, salary: Double) {
        self.name = name
        self.salary = salary
    }
    var description: String { "name: \(name), salary: \(salary)" }
}


// Struct behaviour
print("# Demo 1 - Struct (Value Type)\n")

var originalStruct = EmployeeStruct(name: "Alice", salary: 100_000)
var copiedStruct = originalStruct
copiedStruct.salary = 50_000

/// The copied struct shows a different value to the original
print("Original Struct: \(originalStruct)")
print("Copied Struct:   \(copiedStruct)") // this shows different values

print("\n--------------------\n")

// Class behaviour
print("# Demo 2 - Class (Reference Type)\n")

var originalClass = EmployeeClass(name: "Bob", salary: 100_000)
var copiedClass = originalClass
copiedClass.salary = 50_000

/// The copied class affects both
print("Original Class: \(originalClass)")
print("Copied Class:   \(copiedClass)") // both have changed

print("\n--------------------\n")

// Parent-child relationship
print("# Demo 3 - Parent-child\n")

struct CompanyUsingStructs {
    var employees: [EmployeeStruct]
}

class CompanyUsingClasses {
    var employees: [EmployeeClass]
    init(employees: [EmployeeClass]) {
        self.employees = employees
    }
}

/// the original struct will be unaffected because its a value
var structCompany = CompanyUsingStructs(employees: [EmployeeStruct(name: "Carol", salary: 100_000)])
var copiedStructCompany = structCompany
copiedStructCompany.employees[0].salary = 70_000

print("Original Struct Company: \(structCompany.employees[0])")
print("Copied Struct Company:   \(copiedStructCompany.employees[0])")

print ("\n--------------------\n")

/// the class will afffect the original because its a reference
let classEmployee = EmployeeClass(name: "Dan", salary: 100_000)
let classCompany = CompanyUsingClasses(employees: [classEmployee])
let copiedClassCompany = classCompany
copiedClassCompany.employees[0].salary = 70_000

print("Original Class Company: \(classCompany.employees[0])")
print("Copied Class Company:   \(copiedClassCompany.employees[0])") // original affected

print ("\n--------------------\n")

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()


