-- constraints 
USE courier_logistics_db;

-- test 1 duplicate compsite primary key
 INSERT INTO manifest_parcel
    (manifest_id, parcel_id, sequence_no)
VALUES
    (1, 1, 99);
    
-- test 2 
INSERT INTO manifest_parcel
    (manifest_id, parcel_id, sequence_no)
VALUES
    (9999, 1, 1);
    
    SELECT *
FROM parcel
ORDER BY parcel_id;
    
    
SELECT COUNT(*) AS total_manifest_parcel_records
FROM manifest_parcel;
 