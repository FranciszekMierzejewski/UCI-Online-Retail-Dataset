-- RFM: Recency, Frequency, Monetary scoring
WITH reference_date AS ( -- CTE for Day after last invoice, to compare recency
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
        ROUND(SUM(il.quantity * il.unit_price)::NUMERIC, 2) AS amount_spent -- total amount spent to nearest 2dp
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
),


rfm_recency AS (
    SELECT
        r.*, 
        (rd.cur_date::date - r.last_purchase_date::date) AS recency
    FROM    
        rfm r
    CROSS JOIN reference_date rd -- cartesian join, compute recency on each customer
),


-- Split each measure into 5 quantiles
rfm_scores AS (
    SELECT  
        customer_id,
        amount_spent,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY invoice_count) AS f_score,
        NTILE(5) OVER (ORDER BY amount_spent) AS m_score
    FROM 
        rfm_recency
),


-- weighted sum
rfm_total AS (
    SELECT
        customer_id,
        amount_spent,
        (0.33*r_score + 0.33*f_score + 0.33*m_score) as total
    FROM 
        rfm_scores
    /*
    ORDER BY 
        total
    */
),


rmf_categories AS (
    SELECT
        customer_id,
        amount_spent,
        CASE
            WHEN total >= 4.5 THEN 'Top Customers'
            WHEN total >= 3.5 THEN 'High Value Customers'
            WHEN total >= 2.5 THEN 'Medium Value Customers'
            WHEN total >= 1.5 THEN 'Low Value Customers'
            ELSE 'Lost Customers'
        END AS category
    FROM
        rfm_total
)


-- Summary of customers by RFM 
SELECT
    category,
    COUNT(*) AS customer_count,
    ROUND(SUM(amount_spent)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(amount_spent)::NUMERIC, 2) AS average_revenue_per_customer,
    ROUND(100 * COUNT(*)/SUM(COUNT(*)) OVER(), 2) AS percentage_of_total_customers, -- sum total count over all groups
    ROUND(100 * SUM(amount_spent::NUMERIC)/SUM(SUM(amount_spent::NUMERIC)) OVER(), 2) AS percentage_of_total_revenue
FROM
    rmf_categories
GROUP BY
    category
ORDER BY
    total_revenue DESC;

-- TODO: Customer Retention


