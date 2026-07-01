-- Number of cancellations
SELECT 
    COUNT(*) AS number_of_cancelled_orders
FROM 
    raw_transactions
WHERE
    invoice_no LIKE 'C%'; -- Cancelled orders have invoice_no starting with C


-- Table not including null/cancelled orders
DROP VIEW IF EXISTS non_cancelled_orders;

CREATE VIEW non_cancelled_orders AS 
SELECT *
FROM 
    raw_transactions
WHERE
    invoice_no NOT LIKE 'C%' AND invoice_no IS NOT NULL;


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
    rt.number_of_missing_customer_id,
    rt.number_of_filled_customer_id,
    rt.number_of_unique_customers,
    nco.number_of_unique_customers_successful_sales
FROM (
    SELECT
        COUNT(*) AS total_number_of_rows,
        SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS number_of_missing_customer_id,
        SUM(CASE WHEN customer_id IS NOT NULL THEN 1 ELSE 0 END) AS number_of_filled_customer_id,
        COUNT(DISTINCT customer_id) AS number_of_unique_customers
    FROM raw_transactions
) rt
CROSS JOIN (
    SELECT
        COUNT(DISTINCT customer_id) AS number_of_unique_customers_successful_sales
    FROM non_cancelled_orders
) nco;


SELECT
    COUNT(DISTINCT(rt.customer_id)) AS number_of_unique_customers_not_successful_sales
FROM
    raw_transactions rt
WHERE
    rt.customer_id IS NOT NULL 
    AND NOT EXISTS ( -- NOT EXISTS is a unary operator
        SELECT 
            1
        FROM
            non_cancelled_orders nco
        WHERE  
            nco.customer_id = rt.customer_id
    );


-- negative quantity order of stock
SELECT
    COUNT(*) AS negative_quantity_stock_count
FROM
    non_cancelled_orders
WHERE
    quantity::INT < 0; -- Checked, no double in data


-- non-positive unit price of stock
SELECT
    COUNT(*) AS non_positive_unit_price_count
FROM 
    non_cancelled_orders
WHERE
    unit_price::NUMERIC <= 0;


-- Overall unit price statistics of table
SELECT 
    ROUND(AVG(unit_price::NUMERIC), 2) AS average_unit_price,
    MAX(unit_price::NUMERIC) AS maximum_unit_price,
    MIN(unit_price::NUMERIC) AS minimum_unit_price
FROM
    non_cancelled_orders
WHERE
    customer_id IS NOT NULL
    AND unit_price::NUMERIC > 0
    AND country != 'Unspecified';


-- TODO: Check 'Unspecified' country value, 446 number of orders
SELECT 
    COUNT(DISTINCT customer_id) AS unique_customers_unspecified_country
FROM 
    non_cancelled_orders
WHERE 
    country = 'Unspecified';


-- breakdown of statistics by country
SELECT
    COUNT(*) AS number_of_orders,
    SUM(quantity::NUMERIC) AS quantity,
    ROUND(SUM(unit_price::NUMERIC * quantity::NUMERIC), 2) AS total_revenue,
    ROUND(AVG(unit_price::NUMERIC), 2) AS average_unit_price, -- ignore null value by default
    MAX(unit_price::NUMERIC) AS maximum_unit_price,
    MIN(unit_price::NUMERIC) AS minimum_unit_price,
    country
FROM
    non_cancelled_orders
WHERE 
    customer_id IS NOT NULL
    AND unit_price::NUMERIC > 0
    AND quantity::NUMERIC > 0
GROUP BY 
    country
ORDER BY 
    total_revenue DESC;


-- monthly revenue 
SELECT 
    year,
    month,
    monthly_revenue,
    average_unit_price,
    quantity
FROM
    (
        SELECT
            to_char(DATE_TRUNC('year', invoice_date::TIMESTAMP), 'YYYY') AS year,
            DATE_TRUNC('month', invoice_date::TIMESTAMP) AS start_of_month,
            to_char(DATE_TRUNC('month', invoice_date::TIMESTAMP), 'Month') AS month,
            ROUND(SUM(unit_price::NUMERIC * quantity::NUMERIC), 2) AS monthly_revenue,
            ROUND(AVG(unit_price::NUMERIC), 2) AS average_unit_price,
            SUM(quantity::NUMERIC) AS quantity
        FROM
            non_cancelled_orders
        WHERE
            customer_id IS NOT NULL
            AND unit_price::NUMERIC > 0
            AND quantity::NUMERIC > 0
            AND country != 'Unspecified'
        GROUP BY
            year,
            start_of_month
    ) nco
ORDER BY
    start_of_month;