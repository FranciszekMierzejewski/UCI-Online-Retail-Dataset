-- RFM: Recency, Frequency, Monetary scoring
WITH current_date AS ( -- CTE for Day after last invoice, to compare recency
    SELECT 
        MAX(invoice_date) + INTERVAL '1 day' AS cur_date
    FROM
        invoices
),

rfm AS (
    SELECT
        c.customer_id,
        MAX(i.invoice_date) AS last_purchase_date, -- last purchase date, recency
        COUNT(DISTINCT i.invoice_no) AS invoice_count, -- invoice count, frequency
        ROUND(SUM(il.quantity * il.unit_price)::NUMERIC, 2) AS total_amount_spent -- total amount spent to nearest 2dp
    FROM
        customers c
    JOIN 
        invoices i
        ON i.customer_id = c.customer_id
    JOIN 
        invoice_lines il
        ON il.invoice_no = i.invoice_no
    GROUP BY
        c.customer_id
)

rmf_recency AS (
    SELECT
        r.*, 
        (cd.cur_date::date - r.last_purchase_date::date) AS recency
    FROM    
        rfm r
    CROSS JOIN cd -- cartesian join, compute recency on each customer
)



-- TODO: Customer Retention


