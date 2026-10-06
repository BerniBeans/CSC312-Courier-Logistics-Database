USE courier_logistics_db;

-- find parcels going to bellville (simple) 
SELECT
    parcel_id,
    tracking_number,
    destination_city,
    registration_datetime
FROM parcel
WHERE destination_city = 'Bellville'
ORDER BY registration_datetime;

-- find drivers liscense valid (simple) 
SELECT
    driver_id,
    CONCAT(first_name, ' ', last_name) AS driver_name,
    license_number,
    license_expiry_date
FROM driver
WHERE license_expiry_date > CURDATE()
ORDER BY license_expiry_date;


-- how many parcels each customer sent and total parcel weight (medium) 
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(p.parcel_id) AS total_parcels,
    ROUND(COALESCE(SUM(p.weight_kg), 0), 2) AS total_weight_kg
FROM customer c
LEFT JOIN parcel p
    ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_parcels DESC,
    customer_name;

-- number and weight of parcels carried by each manifest and route(medium) 
SELECT
    dm.manifest_code,
    r.route_name,
    dm.manifest_status,
    COUNT(mp.parcel_id) AS parcels_on_manifest,
    ROUND(COALESCE(SUM(p.weight_kg), 0), 2) AS total_weight_kg
FROM delivery_manifest dm
INNER JOIN route r
    ON dm.route_id = r.route_id
LEFT JOIN manifest_parcel mp
    ON dm.manifest_id = mp.manifest_id
LEFT JOIN parcel p
    ON mp.parcel_id = p.parcel_id
GROUP BY
    dm.manifest_id,
    dm.manifest_code,
    r.route_name,
    dm.manifest_status
ORDER BY dm.manifest_code;

-- Find parcels scans that occur at the hubs or while in transit (medium) 
SELECT
    p.tracking_number,
    DATE(sl.scan_datetime) AS scan_date,
    sl.checkpoint_name,
    sl.status_code,
    sl.staff_note
FROM status_log sl
INNER JOIN parcel p
    ON sl.parcel_id = p.parcel_id
WHERE sl.status_code LIKE '%TRANSIT%'
   OR sl.checkpoint_name LIKE '%Hub%'
ORDER BY sl.scan_datetime;

-- Display the latest known status of each parcel (medium) 
SELECT
    p.tracking_number,
    latest.status_code AS latest_status,
    latest.checkpoint_name AS latest_checkpoint,
    latest.scan_datetime AS latest_scan_time
FROM parcel p
INNER JOIN status_log latest
    ON p.parcel_id = latest.parcel_id
WHERE latest.scan_datetime = (
    SELECT MAX(sl2.scan_datetime)
    FROM status_log sl2
    WHERE sl2.parcel_id = p.parcel_id
)
ORDER BY latest.scan_datetime DESC;

-- identify parcels that have recieved more than 2 tracking scans (complex) 
SELECT
    p.tracking_number,
    CONCAT(c.first_name, ' ', c.last_name) AS sender_name,
    COUNT(sl.status_log_id) AS scan_count,
    MAX(sl.scan_datetime) AS latest_scan_time
FROM parcel p
INNER JOIN customer c
    ON p.customer_id = c.customer_id
LEFT JOIN status_log sl
    ON p.parcel_id = sl.parcel_id
GROUP BY
    p.parcel_id,
    p.tracking_number,
    c.first_name,
    c.last_name
HAVING COUNT(sl.status_log_id) > 2
ORDER BY
    scan_count DESC,
    latest_scan_time DESC;
    
-- analyse vehicle usage by route , shifts manifest and parcels moved(complex) 
SELECT
    v.registration_number,
    v.vehicle_type,
    r.route_name,
    COUNT(DISTINCT sa.shift_assignment_id) AS total_shifts,
    COUNT(DISTINCT dm.manifest_id) AS total_manifests,
    COUNT(DISTINCT mp.parcel_id) AS parcels_moved
FROM vehicle v
INNER JOIN shift_assignment sa
    ON v.vehicle_id = sa.vehicle_id
INNER JOIN route r
    ON sa.route_id = r.route_id
LEFT JOIN delivery_manifest dm
    ON sa.shift_assignment_id = dm.shift_assignment_id
LEFT JOIN manifest_parcel mp
    ON dm.manifest_id = mp.manifest_id
WHERE sa.shift_date
      BETWEEN '2026-10-02' AND '2026-10-05'
GROUP BY
    v.vehicle_id,
    v.registration_number,
    v.vehicle_type,
    r.route_id,
    r.route_name
HAVING
    COUNT(DISTINCT mp.parcel_id) >= 2
    OR COUNT(DISTINCT dm.manifest_id) >= 2
ORDER BY
    parcels_moved DESC,
    total_manifests DESC;
    
-- calculate how much of each vehicle carrying capacity being used (complex) 
SELECT
    dm.manifest_code,
    r.route_name,
    v.registration_number,
    v.capacity_kg,
    ROUND(SUM(p.weight_kg), 2) AS manifest_weight_kg,
    ROUND(
        (SUM(p.weight_kg) / v.capacity_kg) * 100,
        2
    ) AS capacity_used_percent
FROM delivery_manifest dm
INNER JOIN route r
    ON dm.route_id = r.route_id
INNER JOIN shift_assignment sa
    ON dm.shift_assignment_id = sa.shift_assignment_id
INNER JOIN vehicle v
    ON sa.vehicle_id = v.vehicle_id
INNER JOIN manifest_parcel mp
    ON dm.manifest_id = mp.manifest_id
INNER JOIN parcel p
    ON mp.parcel_id = p.parcel_id
GROUP BY
    dm.manifest_id,
    dm.manifest_code,
    r.route_name,
    v.registration_number,
    v.capacity_kg
HAVING
    (SUM(p.weight_kg) / v.capacity_kg) * 100 > 5
ORDER BY capacity_used_percent DESC;

-- find the parcels that have not been delivered and may need operational follow ups 
SELECT
    p.tracking_number,
    CONCAT(c.first_name, ' ', c.last_name) AS sender_name,
    c.email,
    latest.status_code AS latest_status,
    latest.checkpoint_name AS latest_checkpoint,
    latest.scan_datetime AS latest_scan_time,
    TIMESTAMPDIFF(
        HOUR,
        latest.scan_datetime,
        '2026-10-06 17:00:00'
    ) AS hours_since_latest_scan
FROM parcel p

INNER JOIN customer c
    ON p.customer_id = c.customer_id

INNER JOIN (
    SELECT
        parcel_id,
        MAX(scan_datetime) AS latest_scan_datetime
    FROM status_log
    GROUP BY parcel_id
) recent
    ON p.parcel_id = recent.parcel_id

INNER JOIN status_log latest
    ON latest.parcel_id = recent.parcel_id
   AND latest.scan_datetime = recent.latest_scan_datetime

WHERE latest.status_code <> 'DELIVERED'
  AND (
        latest.status_code IN (
            'IN_TRANSIT',
            'ARRIVED_HUB',
            'EXCEPTION',
            'LOADED'
        )
        OR TIMESTAMPDIFF(
            HOUR,
            latest.scan_datetime,
            '2026-10-06 17:00:00'
        ) >= 24
      )

ORDER BY hours_since_latest_scan DESC;







