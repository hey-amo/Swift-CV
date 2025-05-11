/*
 # CoreDataCompany

 A standalone Swift playground project to demonstrate:

 - Core data
 - Entity modeling with multiple relationships
 - One-to-many and one-to-many-through patterns
 - CRUD operations
 - Search/filtering (with NSPredicate)
 
 --

 ## Entities

 - `Company` - Attributes: {name: (String)}. Relationship: departments (1-to-many)
 - `Department`- Attributes: {name: (String)}. Relationship: company (many-to-1), employees (1-to-many)
 - `Employee`- Attributes: {name: (String), role: (String)}. Relationship: department (many-to-1), sales (1-to-many)
 - `Sale` - Attributes: {amount: (Double), date: Date}. Relationship: employee (many-to-1)

 ### Relationships:

 - A `Company` has many `Departments`
 - A `Department` has many `Employees`
 - An `Employee` has many `Sales`

 `Company` → `Department` → `Employee` → `Sale`

 --

 ## Data

 ### Employees

 | Employee ID | Name         | Role              | Department      |
 | ----------- | ------------ | ----------------- | --------------- |
 | E001        | Alice Martin | Sales Manager     | Sales           |
 | E002        | Bob Sanchez  | Software Engineer | Engineering     |
 | E003        | Carol White  | HR Coordinator    | Human Resources |
 | E004        | David Chen   | QA Engineer       | Engineering     |
 | E005        | Eve Summers  | Account Executive | Sales           |

 ### Departments

 | Department ID | Name            | Company   |
 | ------------- | --------------- | --------- |
 | D001          | Sales           | Acme Inc. |
 | D002          | Engineering     | Acme Inc. |
 | D003          | Human Resources | Acme Inc. |

 ### Sales

 | Sale ID | Amount | Date       | Employee     |
 | ------- | ------ | ---------- | ------------ |
 | S001    | 15,000 | 2024-12-01 | Alice Martin |
 | S002    | 9,500  | 2025-01-15 | Eve Summers  |
 | S003    | 12,000 | 2025-02-01 | Alice Martin |
 | S004    | 7,500  | 2025-03-10 | Eve Summers  |
 | S005    | 5,000  | 2025-04-05 | Alice Martin |

*/

import Foundation
import CoreData
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// ---

// MARK: Create the basic core data models

func createCoreDataModels() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    
    // # Entities
    
    /// Company entity
    let company = NSEntityDescription()
    company.name = "Company Ltd"
    company.managedObjectClassName = "Company"
    company.properties = [
       NSAttributeDescription.make(name: "name", type: .stringAttributeType)
    ]
    
    /// Department entity
    let department = NSEntityDescription()
    department.name = "Department"
    department.managedObjectClassName = "Department"
    department.properties = [
        NSAttributeDescription.make(name: "name", type: .stringAttributeType)
    ]
    
    /// Employee entity
    let employee = NSEntityDescription()
    employee.name = "Employee"
    employee.managedObjectClassName = "Employee"
    department.properties = [
        NSAttributeDescription.make(name: "name", type: .stringAttributeType),
        NSAttributeDescription.make(name: "role", type: .stringAttributeType)
    ]
    
    
    /// Sale entity
    let sale = NSEntityDescription()
    sale.name = "Sale"
    sale.managedObjectClassName = "Sale"
    sale.properties = [
        NSAttributeDescription.make(name: "amount", type: .doubleAttributeType),
        NSAttributeDescription.make(name: "date", type: .dateAttributeType)
    ]
    
    // --
    
    // # Relationships
    
    /// A `company` has many `departments`
    let companyToDepartments = NSRelationshipDescription.make(name: "departments", destination: department, toMany: true, inverseName: "company")
    
    /// Each `department` belongs to one `company`
    let departmentToCompany = NSRelationshipDescription.make(name: "company", destination: company, toMany: false, inverseName: "departments")

    /// A `department` has many `employees`
    let departmentToEmployees = NSRelationshipDescription.make(name: "employees", destination: employee, toMany: true, inverseName: "department")
    
    /// An `employee` belongs to one `department`
    let employeeToDepartment = NSRelationshipDescription.make(name: "department", destination: department, toMany: false, inverseName: "employees")

    /// Each `employee` has many `sales`
    let employeeToSales = NSRelationshipDescription.make(name: "sales", destination: sale, toMany: true, inverseName: "employee")
    
    /// Each `sale` belongs to one (a single) `employee`
    let saleToEmployee = NSRelationshipDescription.make(name: "employee", destination: employee, toMany: false, inverseName: "sales")

    /// Add the relationships
    company.properties.append(companyToDepartments)
    department.properties.append(departmentToCompany)

    department.properties.append(departmentToEmployees)
    employee.properties.append(employeeToDepartment)

    employee.properties.append(employeeToSales)
    sale.properties.append(saleToEmployee)
    
    model.entities = [company, department, employee, sale]

    return model
}

// MARK: - Attribute/Relationship Helpers
extension NSAttributeDescription {
    static func make(name: String, type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        return attr
    }
}

extension NSRelationshipDescription {
    static func make(name: String, destination: NSEntityDescription, toMany: Bool, inverseName: String) -> NSRelationshipDescription {
        let rel = NSRelationshipDescription()
        rel.name = name
        rel.destinationEntity = destination
        rel.minCount = 0
        rel.maxCount = toMany ? 0 : 1
        rel.deleteRule = .nullifyDeleteRule
        rel.isOptional = true
        rel.inverseRelationship = nil

        let inverse = NSRelationshipDescription()
        inverse.name = inverseName
        inverse.destinationEntity = rel.entity
        inverse.minCount = 0
        inverse.maxCount = toMany ? 1 : 0
        inverse.deleteRule = .nullifyDeleteRule
        inverse.isOptional = true
        inverse.inverseRelationship = rel
        rel.inverseRelationship = inverse

        // Connect inverses
        rel.inverseRelationship = inverse
        inverse.inverseRelationship = rel

        return rel
    }
}
