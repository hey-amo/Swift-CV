/**
 # Filter, Map, Reduce, Sort
 
 A standalone Swift playground project to demonstrate functional programming using
 - filter, map, reduce, sort
 
 ## Data

  -> See: MockData.md
 
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

struct Company: Hashable, Identifiable {
    let id: Int
    let name: String
}

struct Department: Hashable, Identifiable {
    let id: Int
    let name: String
    let company: Company?
}

struct Employee: Hashable, Identifiable, Equatable {
    let id: Int
    let name: String
    let role: String
    let department: Department?
}

struct Sale: Hashable, Identifiable, Equatable {
    let id: Int
    let amount: Double
    let date: Date
    let employee: Employee
}

// MARK: Create
