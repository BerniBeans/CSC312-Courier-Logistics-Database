# Team Name: Program Pirates
# Group Members: Bernard Bladergroen 4429947, Abdul-Hadi Jacobs 4472374,
# Zandre de Boer 4426284, Eesa Wadee 4496967, James Watt 4417326,
# Zaakira Levy 4493694
# File Name: courier_logistics_app.py
# CSC312 Final Database Practical 2: Courier Logistics Database
# Purpose: Connects to MySQL and runs the 10 required SQL queries.

import getpass
from typing import Any, Dict, List

import mysql.connector
from mysql.connector import Error

DB_NAME = "courier_logistics_db"

QUERIES = [
    {
        "number": 1,
        "level": "Simple",
        "title": "Parcels going to Bellville",
        "purpose": "Shows all parcels with Bellville as the destination city.",
        "sql": """
            SELECT
                parcel_id,
                tracking_number,
                destination_city,
                registration_datetime
            FROM parcel
            WHERE destination_city = 'Bellville'
            ORDER BY registration_datetime;
        """,
    },
    {
        "number": 2,
        "level": "Simple",
        "title": "Drivers with valid licences",
        "purpose": "Confirms which drivers currently have licence dates later than today's date.",
        "sql": """
            SELECT
                driver_id,
                CONCAT(first_name, ' ', last_name) AS driver_name,
                license_number,
                license_expiry_date
            FROM driver
            WHERE license_expiry_date > CURDATE()
            ORDER BY license_expiry_date;
        """,
    },
    {
        "number": 3,
        "level": "Medium",
        "title": "Parcel totals by customer",
        "purpose": "Helps the business identify frequent customers and total parcel weight handled per sender.",
        "sql": """
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
        """,
    },
    {
        "number": 4,
        "level": "Medium",
        "title": "Parcel load per manifest and route",
        "purpose": "Shows the number and weight of parcels consolidated onto each delivery manifest.",
        "sql": """
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
        """,
    },
    {
        "number": 5,
        "level": "Medium",
        "title": "Hub and in-transit status logs",
        "purpose": "Uses string and date functions to find parcel movement through hubs or in-transit checkpoints.",
        "sql": """
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
        """,
    },
    {
        "number": 6,
        "level": "Medium",
        "title": "Latest known status of every parcel",
        "purpose": "Uses a subquery to retrieve the latest status log for every parcel.",
        "sql": """
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
        """,
    },
    {
        "number": 7,
        "level": "Complex",
        "title": "Parcels with more than two scans",
        "purpose": "Uses GROUP BY and HAVING to identify parcels with high tracking activity.",
        "sql": """
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
        """,
    },
    {
        "number": 8,
        "level": "Complex",
        "title": "Vehicle usage by route and shift",
        "purpose": "Combines vehicles, shifts, routes, manifests and parcels to evaluate operational use.",
        "sql": """
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
            WHERE sa.shift_date BETWEEN '2026-10-02' AND '2026-10-05'
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
        """,
    },
    {
        "number": 9,
        "level": "Complex",
        "title": "Manifest capacity usage",
        "purpose": "Compares manifest parcel weight against assigned vehicle capacity.",
        "sql": """
            SELECT
                dm.manifest_code,
                r.route_name,
                v.registration_number,
                v.capacity_kg,
                ROUND(SUM(p.weight_kg), 2) AS manifest_weight_kg,
                ROUND((SUM(p.weight_kg) / v.capacity_kg) * 100, 2) AS capacity_used_percent
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
        """,
    },
    {
        "number": 10,
        "level": "Complex",
        "title": "Parcels requiring operational attention",
        "purpose": "Uses a nested subquery and multiple conditions to find parcels not yet delivered.",
        "sql": """
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
        """,
    },
]


def connect_to_database():
    """Connect to the university MySQL server."""

    host = "172.21.12.21"
    port = 29947

    print("University MySQL connection")
    print(f"Host: {host}")
    print(f"Port: {port}")
    print(f"Database: {DB_NAME}")

    username = input("MySQL username: ").strip()
    password = getpass.getpass("MySQL password: ")

    return mysql.connector.connect(
        host=host,
        port=port,
        user=username,
        password=password,
        database=DB_NAME,
    )


def print_table(rows: List[Dict[str, Any]]) -> None:
    """Print query results as a simple aligned table."""

    if not rows:
        print("No rows returned.")
        return

    headers = list(rows[0].keys())
    widths = {header: len(header) for header in headers}

    for row in rows:
        for header in headers:
            widths[header] = max(
                widths[header],
                len(str(row.get(header, ""))),
            )

    header_line = " | ".join(
        header.ljust(widths[header])
        for header in headers
    )

    print(header_line)
    print("-" * len(header_line))

    for row in rows:
        print(
            " | ".join(
                str(row.get(header, "")).ljust(widths[header])
                for header in headers
            )
        )


def run_query(connection, query_info: Dict[str, Any]) -> None:
    """Execute one SQL query and display the results."""

    print("\n" + "=" * 80)
    print(
        f"Query {query_info['number']} "
        f"({query_info['level']}): "
        f"{query_info['title']}"
    )
    print(f"Purpose: {query_info['purpose']}")
    print("=" * 80)

    with connection.cursor(dictionary=True) as cursor:
        cursor.execute(query_info["sql"])
        rows = cursor.fetchall()
        print_table(rows)


def main() -> None:
    print("Courier Logistics Database Query Runner")
    print(
        "Make sure the courier_logistics_db database "
        "has already been created in MySQL."
    )

    connection = None

    try:
        connection = connect_to_database()
        print(f"\nConnected successfully to: {DB_NAME}")

        while True:
            print("\nMenu")
            print("1. Run all 10 queries")
            print("2. Run one query")
            print("3. Exit")

            choice = input("Choose an option: ").strip()

            if choice == "1":
                for query in QUERIES:
                    run_query(connection, query)

            elif choice == "2":
                query_text = input(
                    "Enter query number (1-10): "
                ).strip()

                if not query_text.isdigit():
                    print("Please enter a number from 1 to 10.")
                    continue

                query_number = int(query_text)

                selected = next(
                    (
                        query
                        for query in QUERIES
                        if query["number"] == query_number
                    ),
                    None,
                )

                if selected is None:
                    print("Invalid query number.")
                else:
                    run_query(connection, selected)

            elif choice == "3":
                print("Exiting program.")
                break

            else:
                print("Invalid option. Please choose 1, 2, or 3.")

    except Error as error:
        print("\nDatabase error:")
        print(error)

    except Exception as error:
        print("\nUnexpected error:")
        print(error)

    finally:
        if connection is not None:
            try:
                if connection.is_connected():
                    connection.close()
                    print("\nMySQL connection closed.")
            except Exception:
                pass


if __name__ == "__main__":
    main()
