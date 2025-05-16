# CoreDataDemo-Notes.md

These are the entities for the core data demo.

## Entities

 - `Company` - Attributes: {name: (String)}. Relationship: departments (1-to-many)
 - `Department`- Attributes: {name: (String)}. Relationship: company (many-to-1), employees (1-to-many)
 - `Employee`- Attributes: {name: (String), role: (String)}. Relationship: department (many-to-1), sales (1-to-many)
 - `Sale` - Attributes: {amount: (Double), date: Date}. Relationship: employee (many-to-1)

### Relationships:

- A `Company` has many `Departments`
- A `Company` has many `Employees` directly
- A `Department` has many `Employees` (many-to-many)
- An `Employee` works in many `Departments` (many-to-many)
- An `Employee` processes many `Sales`
- A `Sale` contains many `Products` (through `SaleItem`)
- A `Product` appears in many `Sales` (through `SaleItem`)

# Relationships high-level visual:

`Company` → `Department` ↔ `Employee` → `Sale` ↔ `Product`

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

### Department_Employee (Junction table for many-to-many)
| Department ID | Employee ID |
| ------------- | ----------- |
| D001          | E001        |
| D001          | E005        |
| D002          | E002        |
| D002          | E004        |
| D003          | E003        |
| D002          | E001        |  

- note on the above table: Alice also works in Engineering

### Employees

| Employee ID | Name         | Role              | Department      |
| ----------- | ------------ | ----------------- | --------------- |
| E001        | Alice Martin | Sales Manager     | Sales           |
| E002        | Bob Sanchez  | Software Engineer | Engineering     |
| E003        | Carol White  | HR Coordinator    | Human Resources |
| E004        | David Chen   | QA Engineer       | Engineering     |
| E005        | Eve Summers  | Account Executive | Sales           |

### Products

| Product ID | Name               | Description              | Price  | SKU       |
| ---------- | ------------------ | ------------------------ | ------ | --------- |
| P001       | Enterprise Suite   | Business software bundle | 5,000  | ENT-S-001 |
| P002       | Security Package   | Cybersecurity solution   | 3,500  | SEC-P-002 |
| P003       | Cloud Storage      | 1TB cloud storage        | 1,200  | CLD-S-003 |
| P004       | Support Contract   | Annual support           | 2,500  | SUP-C-004 |
| P005       | Mobile App License | Corporate app license    | 750    | MOB-A-005 |

### Sales

| Sale ID | Amount | Date       | Employee     |
| ------- | ------ | ---------- | ------------ |
| S001    | 15,000 | 2024-12-01 | Alice Martin |
| S002    | 9,500  | 2025-01-15 | Eve Summers  |
| S003    | 12,000 | 2025-02-01 | Alice Martin |
| S004    | 7,500  | 2025-03-10 | Eve Summers  |
| S005    | 5,000  | 2025-04-05 | Alice Martin |


### Sale_Items (Junction table linking Sales and Products)
| Sale Item ID | Sale ID | Product ID | Quantity | Price At Sale |
| ------------ | ------- | ---------- | -------- | ------------- |
| SI001        | S001    | P001       | 2        | 5,000         |
| SI002        | S001    | P004       | 2        | 2,500         |
| SI003        | S002    | P002       | 2        | 3,500         |
| SI004        | S002    | P005       | 3        | 750           |
| SI005        | S003    | P001       | 1        | 5,000         |
| SI006        | S003    | P002       | 2        | 3,500         |
| SI007        | S004    | P003       | 5        | 1,200         |
| SI008        | S004    | P005       | 2        | 750           |
| SI009        | S005    | P004       | 2        | 2,500         |