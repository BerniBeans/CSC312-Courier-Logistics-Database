-- TeamName: Program Pirates 
-- GroupMembers :  Bernard Bladergroen 4429947, Abdul-Hadi Jacobs 4472374,Zandre de Boer 4426284,Eesa Wadee 4496967,James Watt 4417326  , Zaakira Levy 4493694
-- fileName : courier_logistics-database.sql1
-- CSC312: Prac 2 

 DROP DATABASE IF EXISTS courier_logistics_db;
CREATE DATABASE courier_logistics_db;
USE courier_logistics_db;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS status_log;
DROP TABLE IF EXISTS manifest_parcel;
DROP TABLE IF EXISTS delivery_manifest;
DROP TABLE IF EXISTS shift_assignment;
DROP TABLE IF EXISTS route;
DROP TABLE IF EXISTS vehicle;
DROP TABLE IF EXISTS driver;
DROP TABLE IF EXISTS parcel;
DROP TABLE IF EXISTS customer;

SET FOREIGN_KEY_CHECKS = 1;

-- CUSTOMER
CREATE TABLE customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    street_address VARCHAR(150) NOT NULL,
    city VARCHAR(60) NOT NULL,
    postal_code VARCHAR(10) NOT NULL
) ENGINE=InnoDB;

-- PARCEL
CREATE TABLE parcel (
    parcel_id INT AUTO_INCREMENT PRIMARY KEY,
    tracking_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    registration_datetime DATETIME NOT NULL,
    weight_kg DECIMAL(7,2) NOT NULL,
    length_cm DECIMAL(7,2) NOT NULL,
    width_cm DECIMAL(7,2) NOT NULL,
    height_cm DECIMAL(7,2) NOT NULL,
    destination_street VARCHAR(150) NOT NULL,
    destination_city VARCHAR(60) NOT NULL,
    destination_postal_code VARCHAR(10) NOT NULL,
    service_level VARCHAR(30) NOT NULL DEFAULT 'Standard',

    CONSTRAINT chk_parcel_weight
        CHECK (weight_kg > 0),

    CONSTRAINT chk_parcel_dimensions
        CHECK (
            length_cm > 0
            AND width_cm > 0
            AND height_cm > 0
        ),

    CONSTRAINT fk_parcel_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- DRIVER
CREATE TABLE driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(40) NOT NULL UNIQUE,
    license_expiry_date DATE NOT NULL,
    phone VARCHAR(20) NOT NULL
) ENGINE=InnoDB;

-- VEHICLE
CREATE TABLE vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    registration_number VARCHAR(20) NOT NULL UNIQUE,
    vehicle_type VARCHAR(40) NOT NULL,
    capacity_kg DECIMAL(8,2) NOT NULL,
    vehicle_status VARCHAR(30) NOT NULL DEFAULT 'Available',

    CONSTRAINT chk_vehicle_capacity
        CHECK (capacity_kg > 0)
) ENGINE=InnoDB;

-- ROUTE
CREATE TABLE route (
    route_id INT AUTO_INCREMENT PRIMARY KEY,
    route_name VARCHAR(100) NOT NULL UNIQUE,
    origin_hub VARCHAR(80) NOT NULL,
    destination_hub VARCHAR(80) NOT NULL,
    distance_km DECIMAL(8,2) NOT NULL,
    planned_duration_hours DECIMAL(5,2) NOT NULL,

    CONSTRAINT chk_route_distance
        CHECK (distance_km > 0),

    CONSTRAINT chk_route_duration
        CHECK (planned_duration_hours > 0)
) ENGINE=InnoDB;

-- SHIFT ASSIGNMENT
CREATE TABLE shift_assignment (
    shift_assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    route_id INT NOT NULL,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    UNIQUE KEY uq_driver_shift
        (driver_id, shift_date, start_time),

    UNIQUE KEY uq_vehicle_shift
        (vehicle_id, shift_date, start_time),

    CONSTRAINT fk_shift_driver
        FOREIGN KEY (driver_id)
        REFERENCES driver(driver_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_shift_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES vehicle(vehicle_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_shift_route
        FOREIGN KEY (route_id)
        REFERENCES route(route_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- DELIVERY MANIFEST
CREATE TABLE delivery_manifest (
    manifest_id INT AUTO_INCREMENT PRIMARY KEY,
    manifest_code VARCHAR(30) NOT NULL UNIQUE,
    route_id INT NOT NULL,
    shift_assignment_id INT NULL,
    manifest_date DATE NOT NULL,
    departure_time DATETIME NULL,
    arrival_time DATETIME NULL,
    manifest_status VARCHAR(30) NOT NULL DEFAULT 'Planned',

    CONSTRAINT fk_manifest_route
        FOREIGN KEY (route_id)
        REFERENCES route(route_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_manifest_shift
        FOREIGN KEY (shift_assignment_id)
        REFERENCES shift_assignment(shift_assignment_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- MANIFEST PARCEL
CREATE TABLE manifest_parcel (
    manifest_id INT NOT NULL,
    parcel_id INT NOT NULL,
    loaded_at DATETIME NULL,
    unloaded_at DATETIME NULL,
    sequence_no INT NULL,

    PRIMARY KEY (manifest_id, parcel_id),

    CONSTRAINT fk_mp_manifest
        FOREIGN KEY (manifest_id)
        REFERENCES delivery_manifest(manifest_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_mp_parcel
        FOREIGN KEY (parcel_id)
        REFERENCES parcel(parcel_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_manifest_sequence
        CHECK (
            sequence_no IS NULL
            OR sequence_no > 0
        )
) ENGINE=InnoDB;

-- STATUS LOG
CREATE TABLE status_log (
    status_log_id INT AUTO_INCREMENT PRIMARY KEY,
    parcel_id INT NOT NULL,
    manifest_id INT NULL,
    scan_datetime DATETIME NOT NULL,
    checkpoint_name VARCHAR(100) NOT NULL,
    status_code VARCHAR(30) NOT NULL,
    staff_note VARCHAR(255) NULL,

    CONSTRAINT fk_status_parcel
        FOREIGN KEY (parcel_id)
        REFERENCES parcel(parcel_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_status_manifest
        FOREIGN KEY (manifest_id)
        REFERENCES delivery_manifest(manifest_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_parcel_customer
ON parcel(customer_id);

CREATE INDEX idx_parcel_destination
ON parcel(destination_city);

CREATE INDEX idx_status_parcel_time
ON status_log(parcel_id, scan_datetime);

CREATE INDEX idx_manifest_route
ON delivery_manifest(route_id);

CREATE INDEX idx_shift_route_date
ON shift_assignment(route_id, shift_date);

SHOW TABLES; 

USE courier_logistics_db; 

-- customer data 
INSERT INTO customer
(first_name, last_name, email, phone, street_address, city, postal_code)
VALUES
('Thando', 'Mokoena', 'thando.mokoena@example.com', '0711111001', '10 Main Road', 'Cape Town', '8001'),
('Aisha', 'Patel', 'aisha.patel@example.com', '0711111002', '22 Loop Street', 'Cape Town', '8001'),
('Pieter', 'Jacobs', 'pieter.jacobs@example.com', '0711111003', '5 Voortrekker Road', 'Bellville', '7530'),
('Lindiwe', 'Ndlovu', 'lindiwe.ndlovu@example.com', '0711111004', '18 Market Street', 'Stellenbosch', '7600'),
('Mark', 'Williams', 'mark.williams@example.com', '0711111005', '44 Beach Road', 'Mossel Bay', '6500'),
('Fatima', 'Daniels', 'fatima.daniels@example.com', '0711111006', '91 Station Road', 'Parow', '7500');


-- parcel data 
INSERT INTO parcel
(
    tracking_number,
    customer_id,
    registration_datetime,
    weight_kg,
    length_cm,
    width_cm,
    height_cm,
    destination_street,
    destination_city,
    destination_postal_code,
    service_level
)
VALUES
('CLX100001', 1, '2026-10-01 08:15:00', 12.40, 45, 30, 25, '7 Oak Avenue', 'Bellville', '7530', 'Express'),
('CLX100002', 1, '2026-10-01 09:05:00', 4.80, 30, 20, 12, '12 Bird Street', 'Stellenbosch', '7600', 'Standard'),
('CLX100003', 2, '2026-10-01 10:30:00', 18.70, 60, 40, 35, '50 Victoria Road', 'George', '6529', 'Express'),
('CLX100004', 2, '2026-10-01 11:10:00', 2.50, 25, 18, 10, '2 Durban Road', 'Bellville', '7530', 'Standard'),
('CLX100005', 3, '2026-10-01 12:20:00', 9.30, 40, 28, 22, '71 Voortrekker Road', 'Parow', '7500', 'Standard'),
('CLX100006', 4, '2026-10-02 08:45:00', 7.60, 35, 25, 18, '9 Plein Street', 'Cape Town', '8001', 'Express'),
('CLX100007', 5, '2026-10-02 09:40:00', 21.20, 70, 45, 40, '4 Harbour Road', 'Mossel Bay', '6500', 'Standard'),
('CLX100008', 6, '2026-10-02 10:15:00', 3.10, 22, 15, 8, '11 Long Street', 'Cape Town', '8001', 'Economy'),
('CLX100009', 3, '2026-10-02 11:00:00', 15.00, 55, 35, 25, '31 Dorp Street', 'Stellenbosch', '7600', 'Express'),
('CLX100010', 4, '2026-10-02 12:10:00', 6.90, 32, 24, 16, '88 Main Road', 'George', '6529', 'Standard');

-- driver data 
INSERT INTO driver
(first_name, last_name, license_number, license_expiry_date, phone)
VALUES
('Sipho', 'Khumalo', 'DVR-CPT-1001', '2029-04-30', '0722222001'),
('Nadia', 'Meyer', 'DVR-CPT-1002', '2028-11-15', '0722222002'),
('Jacob', 'Adams', 'DVR-CPT-1003', '2027-08-20', '0722222003'),
('Zanele', 'Dlamini', 'DVR-CPT-1004', '2029-01-10', '0722222004');


-- vehicle data 
INSERT INTO vehicle
(registration_number, vehicle_type, capacity_kg, vehicle_status)
VALUES
('CA123456', 'Panel Van', 250.00, 'Available'),
('CA654321', 'Light Truck', 600.00, 'Available'),
('CA111222', 'Long Haul Truck', 1200.00, 'Available'),
('CA333444', 'Panel Van', 250.00, 'Maintenance Due');


-- route data 
INSERT INTO route
(route_name, origin_hub, destination_hub, distance_km, planned_duration_hours)
VALUES
('CPT Hub to Bellville Hub', 'Cape Town Hub', 'Bellville Hub', 28.50, 1.20),
('CPT Hub to Stellenbosch Hub', 'Cape Town Hub', 'Stellenbosch Hub', 52.00, 1.60),
('Bellville Hub to Parow Depot', 'Bellville Hub', 'Parow Depot', 12.00, 0.50),
('CPT Hub to George Hub', 'Cape Town Hub', 'George Hub', 430.00, 5.80),
('George Hub to Mossel Bay Depot', 'George Hub', 'Mossel Bay Depot', 48.00, 1.00);

-- shift assignmnet data 
INSERT INTO shift_assignment
(driver_id, vehicle_id, route_id, shift_date, start_time, end_time)
VALUES
(1, 1, 1, '2026-10-02', '08:00:00', '16:00:00'),
(2, 2, 2, '2026-10-02', '08:00:00', '16:00:00'),
(3, 3, 4, '2026-10-02', '18:00:00', '23:59:00'),
(1, 1, 3, '2026-10-03', '08:00:00', '14:00:00'),
(4, 4, 5, '2026-10-03', '09:00:00', '15:00:00'),
(2, 2, 1, '2026-10-04', '08:00:00', '16:00:00');

-- delivery manifest data 
INSERT INTO delivery_manifest
(
    manifest_code,
    route_id,
    shift_assignment_id,
    manifest_date,
    departure_time,
    arrival_time,
    manifest_status
)
VALUES
('MNF-2026-001', 1, 1, '2026-10-02', '2026-10-02 08:30:00', '2026-10-02 10:10:00', 'Completed'),
('MNF-2026-002', 2, 2, '2026-10-02', '2026-10-02 08:45:00', '2026-10-02 10:40:00', 'Completed'),
('MNF-2026-003', 4, 3, '2026-10-02', '2026-10-02 18:30:00', '2026-10-02 23:40:00', 'Completed'),
('MNF-2026-004', 3, 4, '2026-10-03', '2026-10-03 08:20:00', '2026-10-03 09:15:00', 'Completed'),
('MNF-2026-005', 5, 5, '2026-10-03', '2026-10-03 09:30:00', NULL, 'In Transit'),
('MNF-2026-006', 1, 6, '2026-10-04', '2026-10-04 08:25:00', NULL, 'Dispatched');

-- mandifest parcel data 
INSERT INTO manifest_parcel
(manifest_id, parcel_id, loaded_at, unloaded_at, sequence_no)
VALUES
(1, 1, '2026-10-02 08:20:00', '2026-10-02 10:05:00', 1),
(1, 4, '2026-10-02 08:22:00', '2026-10-02 10:06:00', 2),
(1, 5, '2026-10-02 08:25:00', '2026-10-02 10:08:00', 3),
(2, 2, '2026-10-02 08:35:00', '2026-10-02 10:35:00', 1),
(2, 9, '2026-10-02 08:38:00', '2026-10-02 10:38:00', 2),
(3, 3, '2026-10-02 18:15:00', '2026-10-02 23:35:00', 1),
(3, 10, '2026-10-02 18:18:00', '2026-10-02 23:36:00', 2),
(4, 5, '2026-10-03 08:10:00', '2026-10-03 09:10:00', 1),
(5, 7, '2026-10-03 09:20:00', NULL, 1),
(6, 6, '2026-10-04 08:15:00', NULL, 1),
(6, 8, '2026-10-04 08:16:00', NULL, 2);

-- status log data 
INSERT INTO status_log
(
    parcel_id,
    manifest_id,
    scan_datetime,
    checkpoint_name,
    status_code,
    staff_note
)
VALUES
(1, NULL, '2026-10-01 08:20:00', 'Cape Town Intake Desk', 'REGISTERED', 'Parcel registered by sender'),
(1, 1, '2026-10-02 08:20:00', 'Cape Town Hub', 'LOADED', 'Loaded onto manifest MNF-2026-001'),
(1, 1, '2026-10-02 10:05:00', 'Bellville Hub', 'ARRIVED_HUB', 'Arrived at Bellville Hub'),
(1, NULL, '2026-10-02 14:25:00', 'Bellville Delivery Zone', 'DELIVERED', 'Delivered to destination'),

(2, NULL, '2026-10-01 09:10:00', 'Cape Town Intake Desk', 'REGISTERED', 'Parcel registered by sender'),
(2, 2, '2026-10-02 08:35:00', 'Cape Town Hub', 'LOADED', 'Loaded for Stellenbosch'),
(2, 2, '2026-10-02 10:35:00', 'Stellenbosch Hub', 'ARRIVED_HUB', 'Arrived at Stellenbosch'),

(3, NULL, '2026-10-01 10:35:00', 'Cape Town Intake Desk', 'REGISTERED', 'Parcel registered'),
(3, 3, '2026-10-02 18:15:00', 'Cape Town Hub', 'LOADED', 'Long haul loading'),
(3, 3, '2026-10-02 23:35:00', 'George Hub', 'ARRIVED_HUB', 'Arrived at George'),

(4, NULL, '2026-10-01 11:15:00', 'Cape Town Intake Desk', 'REGISTERED', 'Parcel registered'),
(4, 1, '2026-10-02 08:22:00', 'Cape Town Hub', 'LOADED', 'Loaded to Bellville'),
(4, NULL, '2026-10-02 13:10:00', 'Bellville Delivery Zone', 'DELIVERED', 'Delivered'),

(5, NULL, '2026-10-01 12:25:00', 'Bellville Intake Desk', 'REGISTERED', 'Parcel registered'),
(5, 1, '2026-10-02 08:25:00', 'Cape Town Hub', 'LOADED', 'Consolidated through Bellville'),
(5, 4, '2026-10-03 08:10:00', 'Bellville Hub', 'IN_TRANSIT', 'Moving to Parow Depot'),

(6, 6, '2026-10-04 08:15:00', 'Cape Town Hub', 'LOADED', 'Manifest dispatched'),
(7, 5, '2026-10-03 09:20:00', 'George Hub', 'IN_TRANSIT', 'Mossel Bay leg in progress'),
(8, 6, '2026-10-04 08:16:00', 'Cape Town Hub', 'LOADED', 'Loaded for Cape Town delivery'),
(9, 2, '2026-10-02 10:38:00', 'Stellenbosch Hub', 'ARRIVED_HUB', 'Awaiting last-mile delivery'),
(10, 3, '2026-10-02 23:36:00', 'George Hub', 'EXCEPTION', 'Address verification required');

SELECT 'customer' AS table_name, COUNT(*) AS total_records FROM customer
UNION ALL
SELECT 'parcel', COUNT(*) FROM parcel
UNION ALL
SELECT 'driver', COUNT(*) FROM driver
UNION ALL
SELECT 'vehicle', COUNT(*) FROM vehicle
UNION ALL
SELECT 'route', COUNT(*) FROM route
UNION ALL
SELECT 'shift_assignment', COUNT(*) FROM shift_assignment
UNION ALL
SELECT 'delivery_manifest', COUNT(*) FROM delivery_manifest
UNION ALL
SELECT 'manifest_parcel', COUNT(*) FROM manifest_parcel
UNION ALL
SELECT 'status_log', COUNT(*) FROM status_log;

