-- Total row count
SELECT 
    COUNT(*) AS number_of_rows 
FROM 
    raw_transactions;

-- Total count of empty customer_id
SELECT 
    COUNT(*) AS number_of_missing_customers
FROM 
    raw_transactions 
WHERE 
    customer_id IS NULL;

-- Number of cancellations
SELECT 
    COUNT(*) AS number_of_cancellations
FROM 
    raw_transactions
WHERE
    invoice_no LIKE 'C%'; -- Cancelled orders have invoice_no starting with C