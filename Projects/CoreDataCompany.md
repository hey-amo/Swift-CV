# CoreDataCompany.md

A standalone Swift playground project to demonstrate:

- Basic Core data functionality
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