/*
 # CoreDataCompany

 A standalone Swift playground project to demonstrate:

 - Basic Core data functionality
 - Entity modeling with multiple relationships
 - One-to-many and one-to-many-through patterns
 - CRUD operations
 - Search/filtering (with NSPredicate)

 Data: CoreDataDemo-notes.md

 ### Features
 
 - Show me:
    - [F01] All employees grouped by department
    - [F02] Total sales per employee
    - [F03] The top salesperson per department
    - [F04] Employees with no sales
    - [F05] Departments with the most employees
    - [F06] Top 3 sales by amount (across all employees)

 - CRUD:
    - [F07] Add 1 new employee to an existing department
    - [F08] Add 1 new department `Marketing`
    - [F09] Move 1 employee to `Marketing`
    - [F10] Delete 1 employee from `Sales`
    - [F11] Delete all employees in `Human Resources`
    - [F12] Find employee matching a name
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

// MARK: [Features]

// MARK: [F01] - All employees grouped by department

func showAllEmployeesByDepartment(context: NSManagedObjectContext) {
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Department")

    do {
        /// Fetch departments
        let departments = try context.fetch(fetchRequest)
        for dept in departments {
            let deptName = dept.value(forKey: "name") as? String ?? "Unknown"
            print ("Department: \(deptName)")
            
            /// List matched employees for department
            
//            ///
//            if let employees = dept.value(forKey: "employees") as? Set<NSManagedObject>, !employees.isEmpty {
//                           for emp in employees {
//                               let name = emp.value(forKey: "name") as? String ?? "(Unnamed)"
//                               let role = emp.value(forKey: "role") as? String ?? "(Unknown Role)"
//                               print("   👤 \(name) – \(role)")
//                           }
//                       } else {
//                           print("[No employees]")
//                       }
        }
        
    } catch {
        print ("[Error] - Could not fetch departments: \(error)")
    }
    
    
    /**
    do {
           let departments = try context.fetch(fetchRequest)
           for dept in departments {
               let deptName = dept.value(forKey: "name") as? String ?? "(Unknown Dept)"
               print("📁 Department: \(deptName)")
               
               if let employees = dept.value(forKey: "employees") as? Set<NSManagedObject>, !employees.isEmpty {
                   for emp in employees {
                       let name = emp.value(forKey: "name") as? String ?? "(Unnamed)"
                       let role = emp.value(forKey: "role") as? String ?? "(Unknown Role)"
                       print("   👤 \(name) – \(role)")
                   }
               } else {
                   print("   ⚠️ No employees")
               }
           }
       } catch {
           print("❌ Failed to fetch departments: \(error)")
       }**/
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
