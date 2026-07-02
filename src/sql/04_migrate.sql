-- Products: most frequent description per stock_code
TRUNCATE TABLE products RESTART IDENTITY CASCADE;
INSERT INTO products (stock_code, description)
SELECT stock_code, description
FROM (
    SELECT
        stock_code,
        description,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM non_cancelled_orders
    GROUP BY stock_code, description
) nco
WHERE rn = 1;


INSERT INTO customers (customer_id, country)
SELECT customer_id, country
FROM (
    SELECT
        customer_id,
        country,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM non_cancelled_orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, country
) nco
WHERE rn = 1;


TRUNCATE TABLE invoices RESTART IDENTITY CASCADE;
INSERT INTO invoices (invoice_no, invoice_date, customer_id)
SELECT
    invoice_no,
    MIN(invoice_date)::TIMESTAMP AS invoice_date,
    MAX(customer_id) AS customer_id
FROM non_cancelled_orders
WHERE customer_id IS NOT NULL
GROUP BY invoice_no;


TRUNCATE TABLE invoice_lines RESTART IDENTITY CASCADE;
INSERT INTO invoice_lines (invoice_no, stock_code, quantity, unit_price)
SELECT
    nco.invoice_no,
    nco.stock_code,
    nco.quantity,
    nco.unit_price
FROM (
    SELECT
        invoice_no,
        stock_code,
        customer_id,
        quantity::INT AS quantity,
        unit_price::NUMERIC AS unit_price
    FROM non_cancelled_orders
) nco
JOIN invoices i 
    ON i.invoice_no = nco.invoice_no
JOIN products p 
    ON p.stock_code = nco.stock_code
WHERE 
    nco.customer_id IS NOT NULL
    AND nco.unit_price > 0
    AND nco.quantity > 0;


SELECT 'customers'     AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products',     COUNT(*) FROM products
UNION ALL
SELECT 'invoices',     COUNT(*) FROM invoices
UNION ALL
SELECT 'invoice_lines',COUNT(*) FROM invoice_lines;

/*
 customers     |      4339
 products      |      4059
 invoices      |     18536
 invoice_lines |    397884

Invoices filtered out because of nulls, cancellations and non-positive quantity and prices filtered out
*/