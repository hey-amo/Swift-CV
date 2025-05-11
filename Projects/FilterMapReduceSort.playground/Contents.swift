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
    let departments: [Department]?
    
    init(id: Int, name: String, departments: [Department]?) {
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
    let company: Company?
    let employees: [Employee]?
    
    init(id: Int, name: String, company: Company?, employees: [Employee]?) {
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
    let department: Department?
    let sales: [Sale]?
    
    init(id: Int, name: String, role: String, department: Department?, sales: [Sale]?) {
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
    let employee: Employee?
    
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

/// Get specific departments
let salesDpt = departments.filter { $0.name == "Sales"}.first!
let engineeringDpt  = departments.filter { $0.name == "Engineering"}.first!
let hrDept  = departments.filter { $0.name == "Human Resources"}.first!

/// Create employees
let employees = [
    Employee(id: 1, name: "Alice Martin", role: "Sales Manager", department: salesDpt, sales: []),
    Employee(id: 2, name: "Bob Sanchez", role: "Software Engineer", department: engineeringDpt, sales: []),
    Employee(id: 3, name: "Carol White", role: "HR Coordinator", department: hrDept, sales: []),
    Employee(id: 4, name: "David Chen", role: "QA Engineer", department: engineeringDpt, sales: []),
    Employee(id: 5, name: "Eve Summers", role: "Account Executive", department: salesDpt, sales: []),
]

/// Create sales
let sales = [
    Sale(id: 1, amount: Double(15000), date: "2024-12-01" , employee: nil), // Alice Martin
    Sale(id: 2, amount: Double(9500), date: "2025-01-15" , employee: nil), // Eve Summers
    Sale(id: 3, amount: Double(12000), date: "2024-12-01" , employee: nil), // Alice Martin
    Sale(id: 4, amount: Double(7500), date: "2025-02-01" , employee: nil), // Eve Summers
    Sale(id: 5, amount: Double(5000), date: "2025-04-05" , employee: nil), // Alice Martin
]

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

// ---

// MARK: Helper functions

func addEmployee(to: Department) {
    
}

func addSale(to: Employee) {
    
}

func printCompanyStucture(company: Company) {
    print("# Company: \(company.name)")
    print ("\n ----------- ")
    
    if let departments = company.departments {
        
        for dept in departments {
            print("  > Dept: \(dept.name)")
            
            if let departmentEmployees = dept.employees {
                
                for emp in departmentEmployees {
                    print("    > Employee: \(emp.name)")
                    
                    if let employeeSales = emp.sales {
                        
                        for sale in employeeSales {
                            print("      > Sale: $\(sale.amount)")
                        }
                        
                    } else {
                        print("      > No sales for this employee")
                    }
                }
                
            }
            else {
                print("    > No employees found for this department")
            }
        }
    }
    else {
        print ("No departments found")
    }
}


func dateFormatter() -> DateFormatter {
    /// Date format helper
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}
