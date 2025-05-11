/**
 # Filter, Map, Reduce, Sort
 
 A standalone Swift playground project to demonstrate functional programming using
 - filter, map, reduce, sort
 
 ## Data

 -> See: MockData.md

 ### Company

 | ID | Name   |
 | ------------- | --------------- |
 | C001  | Acme Inc. |

 ### Departments

 | Department ID | Name            | Company   |
 | ------------- | --------------- | --------- |
 | D001          | Sales           | Acme Inc. |
 | D002          | Engineering     | Acme Inc. |
 | D003          | Human Resources | Acme Inc. |

 ### Employees

 | Employee ID | Name         | Role              | Department      |
 | ----------- | ------------ | ----------------- | --------------- |
 | E001        | Alice Martin | Sales Manager     | Sales           |
 | E002        | Bob Sanchez  | Software Engineer | Engineering     |
 | E003        | Carol White  | HR Coordinator    | Human Resources |
 | E004        | David Chen   | QA Engineer       | Engineering     |
 | E005        | Eve Summers  | Account Executive | Sales           |

 ### Sales

 | Sale ID | Amount | Date       | Employee     |
 | ------- | ------ | ---------- | ------------ |
 | S001    | 15,000 | 2024-12-01 | Alice Martin |
 | S002    | 9,500  | 2025-01-15 | Eve Summers  |
 | S003    | 12,000 | 2025-02-01 | Alice Martin |
 | S004    | 7,500  | 2025-03-10 | Eve Summers  |
 | S005    | 5,000  | 2025-04-05 | Alice Martin |
 
 ### Relationships:

 - A `Company` has many `Departments`
 - A `Department` has many `Employees`
 - An `Employee` has many `Sales`

 `Company` → `Department` → `Employee` → `Sale`

 ### Features

 - Show me:
    - [F01] All employees grouped by department
    - [F02] Total sales per employee
    - [F03] The top salesperson per department
    - [F04] Employees with no sales
    - [F05] Departments with the most employees
    - [F06] Top 3 sales by amount (across all employees)
    - [F07] Sales Leaderboard
 */

import Foundation
import PlaygroundSupport

// MARK: Models

class Company: Hashable, Identifiable, Equatable {
    let id: Int
    let name: String
    var departments: [Department]
    var employees: [Employee] {
        get {
            departments.flatMap { $0.employees }
        }
    }
    
    init(id: Int, name: String, departments: [Department] = []) {
        self.id = id
        self.name = name
        self.departments = departments
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: Company, rhs: Company) -> Bool {
        return (lhs.id == rhs.id)
    }
}

class Department: Hashable, Identifiable, Equatable {
    let id: Int
    let name: String
    weak var company: Company?
    var employees: [Employee]
    
    init(id: Int, name: String, company: Company, employees: [Employee] = []) {
        self.id = id
        self.name = name
        self.company = company
        self.employees = employees
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: Department, rhs: Department) -> Bool {
        return (lhs.id == rhs.id)
    }
}

class Employee: Hashable, Identifiable, Equatable {
    let id: Int
    let name: String
    let role: String
    weak var department: Department?
    var sales: [Sale]
    
    init(id: Int, name: String, role: String, department: Department?, sales: [Sale] = []) {
        self.id = id
        self.name = name
        self.role = role
        self.department = department
        self.sales = sales
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: Employee, rhs: Employee) -> Bool {
        return (lhs.id == rhs.id)
    }
}

class Sale: Hashable, Identifiable, Equatable {
    let id: Int
    let amount: Double
    let date: String
    weak var employee: Employee?
    
    init(id: Int, amount: Double, date: String, employee: Employee?) {
        self.id = id
        self.amount = amount
        self.date = date
        self.employee = employee
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: Sale, rhs: Sale) -> Bool {
        return (lhs.id == rhs.id)
    }
}

/// For [F07] Sales Leaderboard
struct LeaderboardEntry: Hashable, Identifiable, Equatable {
    let id: Int
}

// ---

// MARK: Create data
let company = Company(id: 1, name: "Acme Inc", departments: [])

/// Create departments
let departments = [
    Department(id: 1, name: "Sales", company: company, employees: []),
    Department(id: 2, name: "Engineering", company: company,employees: []),
    Department(id: 3, name: "Human Resources", company: company, employees: []),
]

/// Assign the departments to the company
company.departments = departments

/// Make a dictionary mapping a department to its name
let departmentByName = Dictionary(uniqueKeysWithValues: departments.map { ($0.name, $0) })

/// Create employees
let employees = [
    Employee(id: 1, name: "Alice Martin", role: "Sales Manager", department: departmentByName["Sales"], sales: []),
    Employee(id: 2, name: "Bob Sanchez", role: "Software Engineer", department: departmentByName["Engineering"], sales: []),
    Employee(id: 3, name: "Carol White", role: "HR Coordinator", department: departmentByName["Human Resources"], sales: []),
    Employee(id: 4, name: "David Chen", role: "QA Engineer", department: departmentByName["Engineering"], sales: []),
    Employee(id: 5, name: "Eve Summers", role: "Account Executive", department: departmentByName["Sales"], sales: []),
]

/// Make a dictionary mapping an employee by its name
let employeeByName = Dictionary(uniqueKeysWithValues: employees.map { ($0.name, $0) })

/// Create sales
let sales = [
    Sale(id: 1, amount: Double(15000), date: "2024-12-01" , employee: employeeByName["Alice Martin"]), // Alice Martin
    Sale(id: 2, amount: Double(9500), date: "2025-01-15" , employee: employeeByName["Eve Summers"]), // Eve Summers
    Sale(id: 3, amount: Double(12000), date: "2024-12-01" , employee: employeeByName["Alice Martin"]), // Alice Martin
    Sale(id: 4, amount: Double(7500), date: "2025-02-01" , employee: employeeByName["Eve Summers"]), // Eve Summers
    Sale(id: 5, amount: Double(5000), date: "2025-04-05" , employee: employeeByName["Alice Martin"]), // Alice Martin
]

// Tie everything up

/// Link employees back to their departments
for employee in employees {
    employee.department?.employees.append(employee)
}

/// Link sales back to their employees
for sale in sales {
    sale.employee?.sales.append(sale)
}

printCompanyStructure(company: company)

// MARK: Exit playground

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()

// ---

// MARK: Features

/// [F01] Find: All employees grouped by department
func findAllEmployeesGroupedByDepartment() {
    
}

/// [F02] Find: Total sales per employee
func findTotalSalesPerEmployee() {}

/// [F03] The top salesperson per department
func findTopSalesPersonPerDepartment() {}

/// [F04] Employees with no sales
func findAllEmployeesWithNoSales() {}

/// [F05] Departments with the most employees
func findDepartmentsWithMostEmployees() {}

/// [F06] Top 3 sales by amount (across all employees)
func findTop3SalesByAmount() {}

/// [F07] Sales Leaderboard
func showSalesLeaderboard() {}

// ---

// MARK: Filter functions

/// Uses `filter` to find a matching employee by name
func findEmployeeByName(_ name: String, in employees: [Employee]) -> Employee? {
    guard employees.count > 0 else { return nil }
    return employees.filter { $0.name.lowercased() == name.lowercased() }.first
}
/// Uses `filter` to find match employee by ID
func findEmployeeById(_ id: Int, in employees: [Employee]) -> Employee? {
    guard employees.count > 0 else { return nil }
    return employees.filter { $0.id == id }.first
}

/// Use `filter` to find the first matching department by name
func findFirstDepartmentByName(_ name: String, in departments: [Department]) -> Department? {
    return departments.filter { $0.name == name}.first
}

// ---

// MARK: Helper functions

func addEmployee(to: Department) {
    
}

func addSale(to: Employee) {
    
}

func printCompanyStructure(company: Company) {
    print("# Company: \(company.name)\n---------------")
    
    if company.departments.isEmpty {
        print("No departments found")
        return
    }
    
    for dept in company.departments {
        print("  > Dept: \(dept.name)\n---------------")
        
        
        if dept.employees.isEmpty {
            print("    > No employees found for this department")
            continue
        }
        
        for emp in dept.employees {
            print("    > Employee: \(emp.name)")
            
            if emp.sales.isEmpty {
                print("      > No sales for this employee")
            } else {
                for sale in emp.sales {
                    print("      > Sale: $\(sale.amount)")
                }
            }
        }
    }
}


func dateFormatter() -> DateFormatter {
    /// Date format helper
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}
