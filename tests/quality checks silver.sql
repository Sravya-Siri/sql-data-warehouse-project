/*
=========================================================================================
Quality Checks
=========================================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, and 
    standardization across the 'silver' schemas. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalide date ranges and orders.
    - Data consistency between related fields.

Usage Notice:
    - Run these checks after data loading silver layer.
    - Investigate and resolve any discrepancies found during the checks.
=========================================================================================
*/

-- =======================================================================================
-- Checking 'silver.crm_cust_info
-- =======================================================================================

SELECT * FROM silver.crm_cust_info 

-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No result

SELECT cst_id,
	   count(*) AS FLAG
FROM silver.crm_cust_info 
Group by cst_id 
Having count(*)>1 or cst_id IS NULL;


-- Check for unwarnded Spaces in String Values
-- Expectation: No result

SELECT * FROM silver.crm_cust_info 
WHERE TRIM(CST_FIRSTNAME) != cst_firstname;
    OR TRIM(cst_lastname) != cst_lastname;
    OR TRIM(cst_gndr) != cst_gndr;
    OR TRIM(cst_marital_status) != cst_marital_status;


-- Data Standardization & Consistency

SELECT Distinct cst_gndr FROM silver.crm_cust_info;
SELECT Distinct cst_marital_status FROM silver.crm_cust_info;



-- =======================================================================================
-- Checking 'silver.crm_prd_info
-- =======================================================================================
-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No result

SELECT prd_id,
	   count(*) AS FLAG
FROM silver.crm_prd_info 
Group by prd_id 
Having count(*)>1 or prd_id IS NULL;


-- Check for unwarnded Spaces in String Values
-- Expectation: No result

SELECT prd_nm FROM silver.crm_prd_info WHERE TRIM(prd_nm) != prd_nm;


-- Check for null or negative values
-- Expectation: No result
SELECT prd_cost FROM silver.crm_prd_info where prd_cost is null or prd_cost <0;


-- Data Standardization & Consistency
SELECT DISTINCT prd_line FROM silver.crm_prd_info;


-- Check for Invalid Date Orders
SELECT * FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;


-- =======================================================================================
-- Checking 'silver.crm_sales_details
-- =======================================================================================
-- Check for unwarnded Spaces in String Values
-- Expectation: No result

SELECT sls_prd_key FROM silver.crm_sales_details WHERE TRIM(sls_prd_key) != sls_prd_key;

-- Check Invalid Dates
-- Check for Invalid date orders (Order date > Shipping/Due dates)
-- Convert 0 INTO NULL IN DATES
SELECT NULLIF(sls_order_dt,0) AS sls_order_dt
FROM silver.crm_sales_details 
where sls_order_dt <= 0
OR LEN(sls_order_dt) != 8
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101


SELECT NULLIF(sls_ship_dt,0) AS sls_ship_dt
FROM silver.crm_sales_details 
where sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101
OR sls_ship_dt < sls_order_dt

SELECT NULLIF(sls_due_dt,0) AS sls_due_dt
FROM silver.crm_sales_details 
where sls_due_dt <= 0
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101
OR sls_due_dt < sls_order_dt


-- Checking Sales, quantity and price
-- No Negatives, zero or Nulls are allowed.
/*
	Rules:
		1. If sales is negative, zero or null, dervie it using quantity and price
		2. If price is zero or null, Calculate it using Sales and Quantity
		3. If price is negative, convert it to positive value.
*/

SELECT sls_sales AS sls_sales_old, sls_quantity AS sls_quantity_old,sls_price AS sls_price_old, CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales !=  sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
	   END AS sls_sales,
	   sls_quantity, 
	   CASE WHEN sls_price IS NULL OR sls_price = 0 THEN sls_sales/NULLIF(sls_quantity,0) 
			ELSE ABS(sls_price)
	   END AS sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity 
OR sls_sales is null OR sls_quantity is null OR sls_price is null
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0


-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT DISTINCT 
        sls_sales, 
        sls_quantity,
        sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity 
    OR sls_sales is null 
    OR sls_quantity is null 
    OR sls_price is null
    OR sls_sales <= 0 
    OR sls_quantity <= 0 
    OR sls_price <= 0
ORDER BY sls_sales,sls_quantity,sls_price;


-- =======================================================================================
-- Checking 'silver.erp_cust_az12
-- =======================================================================================
  
-- Check Out-of-Range dates
-- Expectation: Birthdates between 1924-01-01 and Today
SELECT bdate 
FROM silver.erp_cust_az12 
WHERE bdate < '1924-01-01' or bdate > GETDATE();

-- Data Standardization & Consistency
SELECT DISTINCT gen 
FROM silver.erp_cust_az12;

-- =======================================================================================
-- Checking 'silver.erp_loc_a101
-- =======================================================================================
-- Data Standardization & Consistency
SELECT DISTINCT cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;
  
-- =======================================================================================
-- Checking 'silver.erp_px_cat_g1v2
-- =======================================================================================
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT * FROM silver.erp_px_cat_g1v2 
WHERE cat!= TRIM(cat) OR
      subcat!= TRIM(subcat) OR
      maintenance!= TRIM(maintenance)

-- Data Standardization & Consistency
SELECT DISTINCT maintenance FROM silver.erp_px_cat_g1v2;
