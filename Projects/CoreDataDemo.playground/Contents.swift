/*
 # CoreDataCompany

 A standalone Swift playground project to demonstrate:

 - Simple Core data functionality
 - Entity modeling with multiple relationships 
 - CRUD operations
 - Search/filtering (with NSPredicate)

 For data structure, see: CoreDataDemo-notes.md

 ### Demos
 
 - Show me:
    - [Demo-01] All employees grouped by department
    - [Demo-02] Total sales per employee
    - [Demo-03] Employees with no sales
    - [Demo-04] Departments with the most employees
    - [Demo-05] Sales leaderboard

 - CRUD:
    - [Demo-06] Add 1 new employee to `Sales`
    - [Demo-07] Delete 1 employee from `Sales`
    - [Demo-08] Delete all employees in `Human Resources`

 - Search:
    - [Demo-09] Complex Search with NSPredicate
*/

import Foundation
import CoreData
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// ---

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

    // Insert deparment objects
    for deptName in departmentsData {
        /// Insert the department and set attributes: {name, company}
        let dept = NSEntityDescription.insertNewObject(forEntityName: "Department", into: context)
        dept.setValue(deptName, forKey: "name")
        dept.setValue(company, forKey: "company")
        departments[deptName] = dept
    }

    /// Employees list
    let employeesData = [
        ("Alice Martin", "Sales Manager", "Sales"),
        ("Bob Sanchez", "Software Engineer", "Engineering"),
        ("Carol White", "HR Coordinator", "Human Resources"),
        ("David Chen", "QA Engineer", "Engineering"),
        ("Eve Summers", "Account Executive", "Sales")
    ]
    
    var employees: [String: NSManagedObject] = [:]

    // Insert employee objects
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
    
    // Insert sales objects
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
    
    // Explanation:
    // we need to fetch all departments
    // then, loop through each department and get all employees via the employee relationship
    // then, sort the employees by name, if possible
    // then, loop through each employee, printing out the name, role, per department
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Department")

    do {
        /// Fetch departments
        let departments = try context.fetch(fetchRequest)
        for dept in departments {
            let deptName = dept.value(forKey: "name") as? String ?? "Unknown"
            print ("Department: \(deptName)")
            
            // Get employees for this department
            if let employees = dept.value(forKey: "employees") as? Set<NSManagedObject> {
                print ("  # Employees found -- \(employees.count)")
                
                let sortedEmployees = employees.sorted(by: { emp1, emp2 in
                    let name1 = emp1.value(forKey: "name") as? String ?? ""
                    let name2 = emp2.value(forKey: "name") as? String ?? ""
                    return name1 < name2
                })
                
                for employee in sortedEmployees {
                    let empName = employee.value(forKey: "name") as? String ?? ""
                    let empRole = employee.value(forKey: "role") as? String ?? ""
                    print ("  - \(String(describing: empName)), \(String(describing: empRole))")
                }
            }
            else {
                print ("- No employees found -")
            }
            
        }
        
    } catch {
        print ("[Error] - Could not fetch departments: \(error)")
    }

}



// MARK: [Demo-02] Total sales per employee

func showTotalSalesPerEmployee(context: NSManagedObjectContext) {
    print("\n=== [Demo-02] Total sales per employee ===")

    // Explanation:
    // We need to fetch all employees
    // then, loop through each employee, get the sales (via the sales relationship)
    // then, calculate totals
    // then, sort by total sales (highest first)
    
    let employeeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Employee")

    do {
        let employees = try context.fetch(employeeFetchRequest)
        
        // Create an array of tuples to store name, role, total
        var employeeSalesData: [(name: String, role: String, total: Double)] = []

        for employee in employees {
            let empName = employee.value(forKey: "name") as? String ?? ""
            let empRole = employee.value(forKey: "role") as? String ?? ""
            
            var totalSales: Double = 0
            if let sales = employee.value(forKey: "sales") as? Set<NSManagedObject> {
                for sale in sales {
                    if let amount: Double = sale.value(forKey: "amount") as? Double {
                        totalSales += amount
                    }
                }
            }
            
            employeeSalesData.append((name: empName, role: empRole, total: totalSales))
        }
        
        // Sort by total sales (highest first)
        employeeSalesData.sort { $0.total > $1.total }
        
        // Print results
        for employeeData in employeeSalesData {
            let formattedTotal = String(format: "%.2f", employeeData.total)
            print("• \(employeeData.name) (\(employeeData.role)): $\(formattedTotal)")
        }
        
    } catch {
        print ("[Error] - Could not fetch employees: \(error)")
    }
}


// MARK: [Demo-03] Employees with no sales

/// Uses a simple NSPredicate
func showEmployeesWithNoSales(context: NSManagedObjectContext) {
    print("\n=== [Demo-03] Employees with no sales ===")
    
    // Explanation:
    // Fetch employees
    // use predicate to find employees where count = 0
    // then, print out employees (if any)
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Employee")

    // Use NSPredicate to find employees where sales.count is 0, empty
    fetchRequest.predicate = NSPredicate(format: "sales.@count == 0")
    
    do {
        
        let employees = try context.fetch(fetchRequest)

        if employees.isEmpty {
            print ("All employees made sales")
        }
        else {
        
            // Loop through al employees, get departments
            for employee in employees {
                let empName = employee.value(forKey: "name") as? String ?? ""
                let empRole = employee.value(forKey: "role") as? String ?? ""
                
                // Print results
                if let department = employee.value(forKey: "department") as? NSManagedObject {
                    let deptName = department.value(forKey: "name") as? String ?? "Unknown"
                    print("• \(empName) (\(empRole)) - \(deptName) Department")
                } else {
                    print("• \(empName) (\(empRole)) - No Department")
                }
            }
        }
        
    } catch {
        print ("[Error] - Could not fetch employees: \(error)")
    }
}

// MARK: [Demo-04] Departments with the most employees

func showDepartmentsWithMostEmployees(context: NSManagedObjectContext) {
    print("\n=== [Demo-04] Departments with the most employees ===")
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Department")
        
    do {
        /// Fetch departments
        let departments = try context.fetch(fetchRequest)
        
        // Create an array of tuples to store department name and employee count
        var departmentData: [(name: String, employeeCount: Int)] = []
                
        // Loop through each department, create department data
        for dept in departments {
            let deptName = dept.value(forKey: "name") as? String ?? "Unknown"
            let employeeCount = (dept.value(forKey: "employees") as? Set<NSManagedObject>)?.count ?? 0
            
            departmentData.append((name: deptName, employeeCount: employeeCount))
        }
        
        // Sort by employee count (highest first)
        departmentData.sort { $0.employeeCount > $1.employeeCount }
        
        // Print results
        for (index, data) in departmentData.enumerated() {
            let ranking = index + 1
            let employeeText = data.employeeCount == 1 ? "employee" : "employees"
            print("\(ranking). \(data.name): \(data.employeeCount) \(employeeText)")
        }
        
    } catch {
        print ("[Error] - Could not fetch departments: \(error)")
    }
}

// MARK: [Demo-05] Sales leaderboard
func showSalesLeaderboard(context: NSManagedObjectContext) {
    print("\n=== [Demo-05] Sales leaderboard ===")
    
    
    // Fetch all sales with their associated employees
    let salesFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Sale")
    
    // Sort by amount (highest first) and then by date (most recent first)
    salesFetchRequest.sortDescriptors = [
        NSSortDescriptor(key: "amount", ascending: false),
        NSSortDescriptor(key: "date", ascending: false)
    ]
    
    do {
        let sales = try context.fetch(salesFetchRequest)
        
        if sales.isEmpty {
            print("No sales records found")
            return
        }
        
        print("\n🏆 TOP SALES PERFORMANCE")
        print("Rank | Employee Name      | Amount    | Date       | Department")
        print(String(repeating: "-", count: 65))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        for (index, sale) in sales.enumerated() {
            let rank = index + 1
            let amount = sale.value(forKey: "amount") as? Double ?? 0.0
            let date = sale.value(forKey: "date") as? Date ?? Date()
            let formattedAmount = String(format: "$%.2f", amount)
            let formattedDate = dateFormatter.string(from: date)
            
            var employeeInfo = "Unknown Employee"
            var departmentInfo = "Unknown Dept"
            
            if let employee = sale.value(forKey: "employee") as? NSManagedObject {
                let empName = employee.value(forKey: "name") as? String ?? "Unknown"
                employeeInfo = empName
                
                if let department = employee.value(forKey: "department") as? NSManagedObject {
                    let deptName = department.value(forKey: "name") as? String ?? "Unknown"
                    departmentInfo = deptName
                }
            }
            
            // Format the row with proper spacing
            let rankStr = String(format: "%2d", rank)
            let nameStr = employeeInfo.padding(toLength: 18, withPad: " ", startingAt: 0)
            let amountStr = formattedAmount.padding(toLength: 9, withPad: " ", startingAt: 0)
            let dateStr = formattedDate.padding(toLength: 10, withPad: " ", startingAt: 0)
            let deptStr = departmentInfo

            print("\(rankStr)   | \(nameStr) | \(amountStr) | \(dateStr) | \(deptStr)")
            
            // Add trophy emojis for top 3
            if rank == 1 {
                print("     🥇 TOP PERFORMER!")
            } else if rank == 2 {
                print("     🥈 Runner-up")
            } else if rank == 3 {
                print("     🥉 Third place")
            }
        }
        
        print(String(repeating: "-", count: 65))
        print("Total sales records: \(sales.count)")
        
        // Calculate some summary stats
        let totalAmount = sales.reduce(0.0) { sum, sale in
            sum + (sale.value(forKey: "amount") as? Double ?? 0.0)
        }
        let averageAmount = totalAmount / Double(sales.count)
        
        print("Total sales value: $\(String(format: "%.2f", totalAmount))")
        print("Average sale amount: $\(String(format: "%.2f", averageAmount))")
        
    } catch {
        print("[X] Failed to fetch sales: \(error)")
    }
}

// MARK: [Demo-06] Add 1 new employee to `Sales`
func insertNewEmployee(context: NSManagedObjectContext) {
    print("\n=== [Demo-06] Add 1 new employee to `Sales` ===")
    
    // Employee tuple
    let employeeData = (name: "Malik Ali", role: "Customer success", departmentName: "Sales")
    
    // Fetch the Sales department
    let departmentFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Department")
    departmentFetchRequest.predicate = NSPredicate(format: "name == %@", employeeData.departmentName)

    // If department found, Insert the employee
    do {
        let departments = try context.fetch(departmentFetchRequest)
        guard let salesDepartment = departments.first else {
            print(" - Sales department not found - ")
            return
        }
        
        // Create the new employee
        let emp = NSEntityDescription.insertNewObject(forEntityName: "Employee", into: context)
        emp.setValue(employeeData.name, forKey: "name")
        emp.setValue(employeeData.role, forKey: "role")
        emp.setValue(salesDepartment, forKey: "department")

        // Save
        try context.save()
        print("[OK] Employee '\(employeeData.name)' added to \(employeeData.departmentName) department.")

    }
    catch {
        print("[X] Save failed -- error: \(error)")
    }
}

// MARK: [Demo-07] Delete 1 employee from `Sales`
func deleteOneEmployeeFromSales(context: NSManagedObjectContext) {
    print("\n=== [Demo-07] Delete 1 employee from `Sales` ===")
    
    // Remove: ("Eve Summers", "Account Executive", "Sales")
    let employeeToFind = "Eve Summers"
    
    let employeeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Employee")
    employeeFetchRequest.predicate = NSPredicate(format: "name == %@", employeeToFind)
    
    do {
        let employees = try context.fetch(employeeFetchRequest)
        guard let emp = employees.first else {
            print(" - Employee: \(employeeToFind) not found - ")
            return
        }
        
        // Get employee details
        let empName = emp.value(forKey: "name") as? String ?? "Unknown"

        // Delete the employee
        context.delete(emp)

        try context.save()
        print("[OK] Successfully deleted employee '\(empName)'")


    } catch {
        print (" - Error: \(error) -")
    }
    
    // List employees as proof of deletion
    showAllEmployeesByDepartment(context: context)
}

// MARK: [Demo-08] Delete all employees in `Human Resources`
func deleteAllEmployeesFromDepartment(context: NSManagedObjectContext) {
    print("\n=== [Demo-08] Delete all employees in `Human Resources` ===")
    
    let departmentName = "Human Resources"
    
    let departmentFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Department")
    departmentFetchRequest.predicate = NSPredicate(format: "name == %@", departmentName)

    // If department found
    do {
        let departments = try context.fetch(departmentFetchRequest)
        guard let hrDept = departments.first else {
            print(" - HR Department not found - ")
            return
        }
        
        
        // Get all employees in HR department
        if let employees = hrDept.value(forKey: "employees") as? Set<NSManagedObject> {
           let employeeCount = employees.count
           print("Found \(employeeCount) employees in Human Resources department")
           
           if employeeCount > 0 {
               // Delete each employee 1 by 1
               for employee in employees {
                   let empName = employee.value(forKey: "name") as? String ?? "Unknown"
                   print("Deleting employee: \(empName)")
                   context.delete(employee)
               }
               
               // Save the context to commit the deletions
               try context.save()
               print("[OK] Successfully deleted \(employeeCount) employees from Human Resources")
           } else {
               print("- No employees found in Human Resources department -")
           }
        } else {
           print("- No employees found in Human Resources department -")
        }
        
    } catch {
        print (" - Error: \(error) -")
    }
    
}

// MARK: [Demo-09] Complex Search with NSPredicate
/// Search for Employees in Sales OR Engineering with sales > $10,000
func searchDemo(context: NSManagedObjectContext) {
    print("\n=== [Demo-09] Complex Search with NSPredicate ===")
    print(" > Search for Employees in Sales OR Engineering with sales > $10,000")
    
    let employeeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Employee")
    
    // Complex predicate: Find employees who are:
    // 1. In Sales OR Engineering departments
    // 2. AND have total sales amount > $10,000
    // 3. Sort by total sales amount (highest first)
    let complexPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        // Department is Sales OR Engineering
        NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "department.name == %@", "Sales"),
            NSPredicate(format: "department.name == %@", "Engineering")
        ]),
        // Has sales with total amount > $10,000
        NSPredicate(format: "sales.@sum.amount > %f", 10000.0)
    ])
    
    employeeFetchRequest.predicate = complexPredicate
    employeeFetchRequest.fetchLimit = 10  // Limit to 10 results
    
    do {
        let employees = try context.fetch(employeeFetchRequest)
        
        if employees.isEmpty {
            print("No employees found matching the search criteria")
            return
        }
        
        print("Found \(employees.count) employee(s) matching criteria:")
        
        // Create array to sort by total sales
        var employeeData: [(employee: NSManagedObject, totalSales: Double)] = []
        
        for employee in employees {
            let empName = employee.value(forKey: "name") as? String ?? "Unknown"
            let empRole = employee.value(forKey: "role") as? String ?? "Unknown"
            
            // Calculate total sales
            var totalSales: Double = 0
            if let sales = employee.value(forKey: "sales") as? Set<NSManagedObject> {
                for sale in sales {
                    if let amount = sale.value(forKey: "amount") as? Double {
                        totalSales += amount
                    }
                }
            }
            
            employeeData.append((employee: employee, totalSales: totalSales))
        }
        
        // Sort by total sales (highest first)
        employeeData.sort { $0.totalSales > $1.totalSales }
        
        // Display results
        for (index, data) in employeeData.enumerated() {
            let employee = data.employee
            let empName = employee.value(forKey: "name") as? String ?? "Unknown"
            let empRole = employee.value(forKey: "role") as? String ?? "Unknown"
            
            var deptName = "No Department"
            if let department = employee.value(forKey: "department") as? NSManagedObject {
                deptName = department.value(forKey: "name") as? String ?? "Unknown"
            }
            
            let formattedTotal = String(format: "%.2f", data.totalSales)
            print("\(index + 1). \(empName) (\(empRole)) - \(deptName) - Total Sales: $\(formattedTotal)")
        }
        
    } catch {
        print("[X] Search failed: \(error)")
    }
}


// Create the core data stack
let coreDataModel = createCoreDataModel()
let container = makeInMemoryContainer(model: coreDataModel)
let context = container.viewContext

// Create the company data
createCompanyData(context: context)

// ---

// MARK: Run demos

/// - [Demo-01] All employees grouped by department
showAllEmployeesByDepartment(context: context)

/// - [Demo-02] Total sales per employee
showTotalSalesPerEmployee(context: context)

/// - [Demo-03] Employees with no sales
showEmployeesWithNoSales(context: context)

/// - [Demo-04] Departments with the most employees
showDepartmentsWithMostEmployees(context: context)

/// - [Demo-05] Sales leaderboard
showSalesLeaderboard(context: context)

/// - [Demo-06] Add 1 new employee to `Sales`
insertNewEmployee(context: context)

/// - [Demo-07] Delete 1 employee from `Sales`
deleteOneEmployeeFromSales(context: context)

/// - [Demo-08] Delete all employees in `Human Resources`
deleteAllEmployeesFromDepartment(context: context)

/// - [Demo-09] Complex Search with NSPredicate
searchDemo(context: context)

print ("\n--------------------\n")

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()
