/*
 # CoreDataCompany

 A standalone Swift playground project to demonstrate:

 - Basic Core data functionality
 - Entity modeling with multiple relationships
 - One-to-many and one-to-many-through patterns
 - CRUD operations
 - Search/filtering (with NSPredicate)

 Data: CoreDataDemo-notes.md

 ### Demos
 
 - Show me:
    - [Demo-01] All employees grouped by department
    - [Demo-02] Total sales per employee
    - [Demo-03] The top salesperson per department
    - [Demo-04] Employees with no sales
    - [Demo-05] Departments with the most employees
    - [Demo-06] Top 3 sales by amount (across all employees)

 - CRUD:
    - [Demo-07] Add 1 new employee to an existing department
    - [Demo-08] Add 1 new department `Marketing`
    - [Demo-09] Move 1 employee to `Marketing`
    - [Demo-10] Delete 1 employee from `Sales`
    - [Demo-11] Delete all employees in `Human Resources`
*/

import Foundation
import CoreData
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// ---

// MARK: In-memory container

/// Set up NSPersistentContainer with an in-memory store,
/// which automatically resets each time the Playground runs.
func makeInMemoryContainer(model: NSManagedObjectModel) -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "Model", managedObjectModel: model)

    let storeDescription = NSPersistentStoreDescription()
    storeDescription.type = NSInMemoryStoreType  // Use in-memory store
    container.persistentStoreDescriptions = [storeDescription]

    container.loadPersistentStores { (desc, error) in
        if let error = error {
            fatalError("[X] Failed to load in-memory store: \(error)")
        } else {
            print("[OK] In-memory store loaded successfully.")
        }
    }

    return container
}


// MARK: Create the basic core data model

func createCoreDataModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    
    // # Entities
    
    /// Company entity
    let company = NSEntityDescription()
    company.name = "Company"  // Fixed: was "Company Ltd"
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
    employee.properties = [  // Fixed: was using department.properties
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
    
    // # Relationships - Create them separately first, then set up inverses
    
    /// Company -> Departments (one-to-many)
    let companyToDepartments = NSRelationshipDescription()
    companyToDepartments.name = "departments"
    companyToDepartments.destinationEntity = department
    companyToDepartments.minCount = 0
    companyToDepartments.maxCount = 0  // 0 means unlimited (to-many)
    companyToDepartments.deleteRule = .nullifyDeleteRule
    companyToDepartments.isOptional = true
    
    let departmentToCompany = NSRelationshipDescription()
    departmentToCompany.name = "company"
    departmentToCompany.destinationEntity = company
    departmentToCompany.minCount = 0
    departmentToCompany.maxCount = 1  // to-one
    departmentToCompany.deleteRule = .nullifyDeleteRule
    departmentToCompany.isOptional = true
    
    // Set up inverse relationships
    companyToDepartments.inverseRelationship = departmentToCompany
    departmentToCompany.inverseRelationship = companyToDepartments

    /// Department -> Employees (one-to-many)
    let departmentToEmployees = NSRelationshipDescription()
    departmentToEmployees.name = "employees"
    departmentToEmployees.destinationEntity = employee
    departmentToEmployees.minCount = 0
    departmentToEmployees.maxCount = 0  // to-many
    departmentToEmployees.deleteRule = .nullifyDeleteRule
    departmentToEmployees.isOptional = true
    
    let employeeToDepartment = NSRelationshipDescription()
    employeeToDepartment.name = "department"
    employeeToDepartment.destinationEntity = department
    employeeToDepartment.minCount = 0
    employeeToDepartment.maxCount = 1  // to-one
    employeeToDepartment.deleteRule = .nullifyDeleteRule
    employeeToDepartment.isOptional = true
    
    // Set up inverse relationships
    departmentToEmployees.inverseRelationship = employeeToDepartment
    employeeToDepartment.inverseRelationship = departmentToEmployees

    /// Employee -> Sales (one-to-many)
    let employeeToSales = NSRelationshipDescription()
    employeeToSales.name = "sales"
    employeeToSales.destinationEntity = sale
    employeeToSales.minCount = 0
    employeeToSales.maxCount = 0  // to-many
    employeeToSales.deleteRule = .nullifyDeleteRule
    employeeToSales.isOptional = true
    
    let saleToEmployee = NSRelationshipDescription()
    saleToEmployee.name = "employee"
    saleToEmployee.destinationEntity = employee
    saleToEmployee.minCount = 0
    saleToEmployee.maxCount = 1  // to-one
    saleToEmployee.deleteRule = .nullifyDeleteRule
    saleToEmployee.isOptional = true
    
    // Set up inverse relationships
    employeeToSales.inverseRelationship = saleToEmployee
    saleToEmployee.inverseRelationship = employeeToSales

    /// Add the relationships to entities
    company.properties.append(companyToDepartments)
    department.properties.append(contentsOf: [departmentToCompany, departmentToEmployees])
    employee.properties.append(contentsOf: [employeeToDepartment, employeeToSales])
    sale.properties.append(saleToEmployee)
    
    model.entities = [company, department, employee, sale]

    return model
}

/// Create company data from the mock data tables
/// Insert Company: One record: Acme Inc.
/// Insert Departments: 3 total (Sales, Engineering, Human Resources)
/// Insert Employees: 5 employees, each linked to a department
/// Insert Sales: 5 sales, only for Sales department employees
func createCompanyData(context: NSManagedObjectContext) {
    
    /// Company
    let company = NSEntityDescription.insertNewObject(forEntityName: "Company", into: context)
    company.setValue("Acme Inc.", forKey: "name")
    
    /// Departments
    let departmentsData = [
        "Sales",
        "Engineering",
        "Human Resources"
    ]
    var departments: [String: NSManagedObject] = [:]

    for deptName in departmentsData {
        /// Insert the department and set attributes: {name, company}
        let dept = NSEntityDescription.insertNewObject(forEntityName: "Department", into: context)
        dept.setValue(deptName, forKey: "name")
        dept.setValue(company, forKey: "company")
        departments[deptName] = dept
    }

    /// Employees
    let employeesData = [
        ("Alice Martin", "Sales Manager", "Sales"),
        ("Bob Sanchez", "Software Engineer", "Engineering"),
        ("Carol White", "HR Coordinator", "Human Resources"),
        ("David Chen", "QA Engineer", "Engineering"),
        ("Eve Summers", "Account Executive", "Sales")
    ]
    
    var employees: [String: NSManagedObject] = [:]

    for (name, role, deptName) in employeesData {
        guard let dept = departments[deptName] else { continue }

        let emp = NSEntityDescription.insertNewObject(forEntityName: "Employee", into: context)
        emp.setValue(name, forKey: "name")
        emp.setValue(role, forKey: "role")
        emp.setValue(dept, forKey: "department")
        employees[name] = emp
    }

    /// Sales
    let salesData: [(employeeName: String, amount: Double, date: String)] = [
        ("Alice Martin", 15000, "2024-12-01"),
        ("Eve Summers", 9500, "2025-01-15"),
        ("Alice Martin", 12000, "2025-02-01"),
        ("Eve Summers", 7500, "2025-03-10"),
        ("Alice Martin", 5000, "2025-04-05")
    ]
    
    /// Date format
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    for (empName, amount, dateString) in salesData {
        guard let emp = employees[empName], let date = formatter.date(from: dateString) else { continue }
        
        let sale = NSEntityDescription.insertNewObject(forEntityName: "Sale", into: context)
        sale.setValue(amount, forKey: "amount")
        sale.setValue(date, forKey: "date")
        sale.setValue(emp, forKey: "employee")
    }
    
    /// Save
    do {
        try context.save()
        print("[OK] Data inserted.")
    } catch {
        print("[X] Save failed -- \(error)")
    }
}


// MARK: [Demos]

// MARK: [Demo-01] - All employees grouped by department

func showAllEmployeesByDepartment(context: NSManagedObjectContext) {
    print("\n=== [Demo-01] All employees grouped by department ===")
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Department")

    do {
        /// Fetch departments
        let departments = try context.fetch(fetchRequest)
        for dept in departments {
            let deptName = dept.value(forKey: "name") as? String ?? "Unknown"
            print ("Department: \(deptName)")
            
            /// Get employees for this department using the relationship
//               if let employees = dept.value(forKey: "employees") as? Set<NSManagedObject> {
//                   for employee in employees.sorted(by: { emp1, emp2 in
//                       let name1 = emp1.value(forKey: "name") as? String ?? ""
//                       let name2 = emp2.value(forKey: "name") as? String ?? ""
//                       return name1 < name2
//                   }) {
//                       let empName = employee.value(forKey: "name") as? String ?? "Unknown"
//                       let empRole = employee.value(forKey: "role") as? String ?? "Unknown"
//                       print("  - \(empName) (\(empRole))")
//                   }
//               }
        }
        
    } catch {
        print ("[Error] - Could not fetch departments: \(error)")
    }

}

// MARK: [Demo-02] Total sales per employee
// MARK: [Demo-03] The top salesperson per department
// MARK: [Demo-04] Employees with no sales
// MARK: [Demo-05] Departments with the most employees
// MARK: [Demo-06] Top 3 sales by amount (across all employees)

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

// MARK: Run demos


// Create the core data stack
let coreDataModel = createCoreDataModel()
let container = makeInMemoryContainer(model: coreDataModel)
let context = container.viewContext

createCompanyData(context: context)


showAllEmployeesByDepartment(context: context)


//try? await Task.sleep(nanoseconds: 1_000_000_000)

print ("\n--------------------\n")

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()
