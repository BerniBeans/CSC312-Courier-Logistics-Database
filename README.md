# CSC312-Courier-Logistics-Database
Courier Logistics Database System - CSC312 Final Database Practical 2
# Courier Logistics Database System
**CSC312 – Database Practical Assignment 2**

**Team Name:** Program Pirates

## 1. Project Overview

This project involves the design and implementation of a relational database for a regional courier logistics company.

The database supports parcel registration, customer information, delivery routes, vehicle and driver assignments, delivery manifests, and parcel tracking through checkpoint scans.

The system was developed using MySQL for database implementation and Python for executing SQL queries.

## 2. Database Design

The database consists of nine tables:

1. CUSTOMER – Stores customer details.
2. PARCEL – Stores parcel information, tracking numbers and delivery destinations.
3. DRIVER – Stores driver information and licence details.
4. VEHICLE – Stores delivery vehicle information.
5. ROUTE – Stores planned delivery routes.
6. SHIFT_ASSIGNMENT – Links drivers, vehicles and routes to operational shifts.
7. DELIVERY_MANIFEST – Records parcels transported on particular routes.
8. MANIFEST_PARCEL – Resolves the many-to-many relationship between parcels and delivery manifests.
9. STATUS_LOG – Records parcel tracking information and checkpoint scans.

The database was designed to Third Normal Form (3NF) to reduce data redundancy and improve data integrity.

Primary keys, foreign keys, unique constraints and check constraints are implemented to maintain data consistency.

## 3. Repository Files

| File | Description |
| `courier_logistics_database.sql` | Creates the database, tables, constraints, indexes and sample data. |
| `courier_logistics_queries.sql` | Contains the SQL queries used to retrieve business information. |
| `courier_logistics_app.py` | Python application that connects to MySQL and executes the ten queries. |
| `constraints_test.sql` | Tests database constraints, including duplicate primary keys and invalid foreign keys. |
| `Courier_Logistics_Model.mwb` | MySQL Workbench database model containing the entity relationships. |
| `README.md` | Explains the project and how to run it. |

## 4. Software Requirements

The following software is required:

- Python 3
- MySQL Server
- MySQL Workbench (recommended)
- MySQL Connector for Python
- Access to the configured MySQL database server

Install the required Python connector by running:

`pip install mysql-connector-python`

## 5. How to Set Up the Database

**Step 1: Download the project**

Download the repository files using the green **Code → Download ZIP** option on GitHub, or clone the repository.

**Step 2: Connect to MySQL**

Open MySQL Workbench and connect to a MySQL server using valid credentials.

For the university server, use the connection details provided for the practical assignment.

**Step 3: Create the database**

Open `courier_logistics_database.sql` in MySQL Workbench.

Execute the SQL script to create the `courier_logistics_db` database, its nine tables and the sample records.

**Important:** The SQL script includes `DROP DATABASE IF EXISTS`. Running it replaces an existing database with the same name, so existing data in that database will be lost.

**Step 4: Verify the database**

After successful execution, run:

`USE courier_logistics_db;`

`SHOW TABLES;`

The result should display the nine database tables.

## 6. How to Run the Python Application

**Step 1:** Open a terminal or command prompt in the folder containing `courier_logistics_app.py`.

**Step 2:** Run the following command:

`python courier_logistics_app.py`

**Step 3:** Enter the MySQL username and password when prompted.

The Python application is configured to connect to the university MySQL server using:

- Host: `172.21.12.21`
- Port: `29947`
- Database: `courier_logistics_db`

The configured server must be accessible from the computer running the application. If another MySQL server is used, the connection settings in the Python file must be updated.

**Step 4:** Once connected successfully, the following menu is displayed:

1. Run all 10 queries
2. Run one query
3. Exit

Choose option 1 to execute all SQL queries, or option 2 to execute an individual query by entering its number.

The results are displayed in the terminal as formatted tables.

Option 3 exits the application and closes the database connection.

## 7. SQL Queries

The project contains ten SQL queries:

**Simple queries (2)**

1. Parcels going to Bellville.
2. Drivers with valid licences.

**Medium queries (4)**

3. Parcel totals by customer.
4. Parcel load per manifest and route.
5. Hub and in-transit status logs.
6. Latest known status of every parcel.

**Complex queries (4)**

7. Parcels with more than two scans.
8. Vehicle usage by route and shift.
9. Manifest capacity usage.
10. Parcels requiring operational attention.

These queries demonstrate SQL filtering, joins, aggregation, grouping, subqueries, date functions and HAVING conditions.

The results provide information useful for parcel tracking, operational planning, vehicle capacity monitoring and customer support.

Some queries use fixed October 2026 dates to demonstrate results using the project's sample records.

## 8. Testing and Validation

The project includes tests to evaluate whether database constraints are enforced correctly.

The `constraints_test.sql` file contains test statements for checking duplicate primary-key entries and invalid foreign-key references.

These negative tests are expected to produce database errors when constraints work correctly. They should be run separately from the normal database setup.

The Python application also includes error handling for database connection and query execution problems.

## 9. Important Notes

- The MySQL database must be created and populated before running the Python application.
- A valid MySQL username and password are required.
- The university server may require access through the university network or an authorised connection.
- MySQL credentials are entered at runtime and are not stored directly in the Python application.
- The application is a database query runner, not a graphical courier management system.

## 10. Project Team

**Program Pirates**

- Bernard Bladergroen
- Abdul-Hadi Jacobs
- Zandré de Boer
- Eesa Wadee
- James Watt
- Zaakira Levy

**Module:** CSC312 – Database Systems

**Institution:** University of the Western Cape
