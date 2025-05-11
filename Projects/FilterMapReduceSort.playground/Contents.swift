/**
 # Filter, Map, Reduce, Sort
 
 A standalone Swift playground project to demonstrate functional programming using
 - filter, map, reduce, sort
 
 ## Data

 -> See: MockData.md

 ### Features

 - Show me:
    - [F00] Company structure output
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

// ---

// MARK: Tie relationships

/// Link employees back to their departments
for employee in employees {
    employee.department?.employees.append(employee)
}

/// Link sales back to their employees
for sale in sales {
    sale.employee?.sales.append(sale)
}


// ---

// MARK: Features:

/*
- [F00] Company structure output
- [F01] All employees grouped by department
- [F02] Total sales per employee
- [F03] The top salesperson per department
- [F04] Employees with no sales
- [F05] Departments with the most employees
- [F06] Top 3 sales by amount (across all employees)
- [F07] Sales Leaderboard
*/

// - [F00] Company structure output
print ("# [F00] - Company structure\n")
printCompanyStructure(for: company)

print ("\n--------------------\n")

// - [F01] All employees grouped by department
print ("# [F01] - All employees grouped by department \n")
showAllEmployeesGroupedByDepartment(in: company)

print ("\n--------------------\n")

// - [F02] Total sales per employee
print ("# [F02] Total sales per employee \n")
showTotalSalesPerEmployee(in: company)

print ("\n--------------------\n")

// - [F03] The top salesperson per department
print ("# [F03] The top salesperson per department \n")
showTopSalesPersonPerDepartment(in: company)
    
print ("\n--------------------\n")


// - [F04] Employees with no sales
print ("# [F04] Employees with no sales \n")
showAllEmployeesWithNoSales(in: company)

print ("\n--------------------\n")

// - [F05] Departments with the most employees
print ("# [F05] Departments with the most employees \n")
showAllDepartmentsWithMostEmployees(in: company)

print ("\n--------------------\n")


// - [F06] Top 3 sales by amount (across all employees)
print ("# [F06] Top 3 sales by amount (across all employees) \n")
showTop3SalesByAmount(in: company)

print ("\n--------------------\n")

// - [F07] Sales Leaderboard
print ("# [F07] Sales Leaderboard \n")
showSalesLeaderboard(for: company)

print ("\n--------------------\n")


// MARK: Exit playground

print("\n\n-- Exiting Playground -- ")
PlaygroundPage.current.finishExecution()




// ---

// MARK: Features

/// [F00] Company structure output

func printCompanyStructure(for company: Company) {
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

/// - [F01] All employees grouped by department
func showAllEmployeesGroupedByDepartment(in company: Company) {
    if (company.departments.isEmpty) {
        print ("[X] No departments found")
        return
    }
       
    company.departments
        .filter {
            !$0.employees.isEmpty
        }
        .forEach { dept in
            print("📁 \(dept.name):")
            dept.employees
                .map { "  👤 \($0.name) – \($0.role)" }
                .forEach { print ($0) }
        }
}

// - [F02] Total sales per employee
func showTotalSalesPerEmployee(in company: Company) {
    if (company.employees.isEmpty) {
        print ("[X] No employees found")
        return
    }

    let allEmployees = company.departments.flatMap { $0.employees }
    allEmployees.forEach { emp in
        let total = emp.sales.reduce(0.0) { $0 + $1.amount }
        print("👤 \(emp.name): $\(total)")
    }
}

// - [F03] The top salesperson per department
func showTopSalesPersonPerDepartment(in company: Company) {
    if (company.departments.isEmpty) {
        print ("[X] No departments found")
        return
    }
    
    /// Loop through each department in the company
    for dept in company.departments {
        let employees = dept.employees
        guard !employees.isEmpty else {
            print("📁 \(dept.name) has no employees")
            continue
        }
        
        /// Finds the maximum element in the employees array
        /// Compare 2 employees in the department
        /// For each, sum up their total sales, and use a comparison to sort higher total sales
        /// May be nil
        let top = employees.max(by: {a, b in
            a.sales.reduce(0.0, { $0 + $1.amount } ) <
                b.sales.reduce(0.0, {$0 + $1.amount})
        } )
        
        if let top = top {
            let total = top.sales.reduce(0.0) { $0 + $1.amount }
            print (" `\(dept.name)` top seller is \(top.name) - $\(total)" )
        }
        
    }
}

// - [F04] Employees with no sales
func showAllEmployeesWithNoSales(in company: Company) {
    let allEmployees = company.departments.flatMap { $0.employees }

    
    let noSalesEmployees = allEmployees.filter {
           $0.sales.isEmpty || $0.sales.reduce(0.0) { $0 + $1.amount } <= 0.0
       }
    
    
    
    if noSalesEmployees.isEmpty {
            print("All employees have sales.")
        } else {
            noSalesEmployees.forEach {
                print("👤 \($0.name) – \($0.role) has no sales")
            }
        }
}

// - [F05] Departments with the most employees
func showAllDepartmentsWithMostEmployees(in company: Company) {
    let _ = company.departments.flatMap { return $0.employees }
    
    /// Find and display departments sorted by how many employees they have, descending.
    let sortedResults = company.departments.sorted {
        return $0.employees.count > $1.employees.count
    }
    
    sortedResults.forEach { result in
        print ( "\(result.name) has \(result.employees.count) employees \n" )
    }
}

// - [F06] Top 3 sales by amount (across all employees)
func showTop3SalesByAmount(in company: Company) {
    
}

// - [F07] Sales Leaderboard
func showSalesLeaderboard(for company: Company) {
    
}

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

func dateFormatter() -> DateFormatter {
    /// Date format helper
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}

struct NumberFormatCache {
    static let currencyRateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.allowsFloats = false
        formatter.roundingMode = .ceiling
        formatter.alwaysShowsDecimalSeparator = false
        return formatter
    }()
}

/*
func numberFormatter(amount: Int, locale: String = "en_US") -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: locale)
    formatter.numberStyle = .currency
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 0
    formatter.allowsFloats = false
    formatter.roundingMode = .ceiling
    formatter.alwaysShowsDecimalSeparator = false
    return formatter
}
*/
