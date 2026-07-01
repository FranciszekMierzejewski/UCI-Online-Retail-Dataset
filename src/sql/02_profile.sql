-- Number of cancellations
SELECT 
    COUNT(*) AS number_of_cancellations
FROM 
    raw_transactions
WHERE
    invoice_no LIKE 'C%'; -- Cancelled orders have invoice_no starting with C


-- Table not including cancelled orders
DROP VIEW IF EXISTS non_cancelled_orders;

CREATE VIEW non_cancelled_orders AS 
SELECT *
FROM 
    raw_transactions
WHERE
    invoice_no NOT LIKE 'C%';


-- Number of sales that went ahead by stock_code
SELECT
    stock_code,
    COUNT(*) AS number_of_successful_sales
FROM 
    non_cancelled_orders
GROUP BY
    stock_code
ORDER BY
    number_of_successful_sales DESC
LIMIT
    10;


-- Row count
SELECT
    rt.total_number_of_rows,
    rt.number_of_missing_rows,
    rt.number_of_filled_rows,
    rt.number_of_unique_customers,
    nco.number_of_unique_customers_that_completed_orders
FROM (
    SELECT
        COUNT(*) AS total_number_of_rows,
        SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS number_of_missing_rows,
        SUM(CASE WHEN customer_id IS NOT NULL THEN 1 ELSE 0 END) AS number_of_filled_rows,
        COUNT(DISTINCT customer_id) AS number_of_unique_customers
    FROM raw_transactions
) rt
CROSS JOIN (
    SELECT
        COUNT(DISTINCT customer_id) AS number_of_unique_customers_that_completed_orders
    FROM non_cancelled_orders
) nco;


