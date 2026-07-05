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
        ((r_score + f_score + m_score)/3) as total
    FROM 
        rfm_scores
    /*
    ORDER BY 
        total
    */
),


rfm_categories AS (
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
    rfm_categories
GROUP BY
    category
ORDER BY
    total_revenue DESC;


-- Customer Retention
WITH first_purchase AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS first_month
    FROM
        invoices
    GROUP BY
        customer_id
),


customer_active_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoice_date) AS active_month
    FROM
        invoices
),


customer_month_diff AS (
    SELECT
        fp.customer_id,
        fp.first_month,
        cam.active_month,
        (
            (EXTRACT(YEAR FROM cam.active_month) - EXTRACT(YEAR FROM fp.first_month)) * 12 -- convert to months
            + (EXTRACT(MONTH FROM cam.active_month) - EXTRACT(MONTH FROM fp.first_month))
        ) AS months_since_first_purchase
    FROM
        first_purchase fp
    JOIN customer_active_months cam
        ON cam.customer_id = fp.customer_id
), 


size_of_first_purchase_by_month AS (
    SELECT
        first_month,
        COUNT(DISTINCT customer_id) AS customer_count
    FROM
        customer_month_diff
    WHERE
        months_since_first_purchase = 0
    GROUP BY
        first_month
),


retention AS (
    SELECT
        cmd.first_month,
        cmd.months_since_first_purchase,
        COUNT(DISTINCT(cmd.customer_id)) AS returning_customers
    FROM
        customer_month_diff cmd
    GROUP BY
        cmd.first_month, cmd.months_since_first_purchase
)


-- Start at month, note how many customers had at least 1 invoice in the next up to 12 months
SELECT
    TO_CHAR(r.first_month, 'YYYY-MM') AS cohort,
    sfpm.customer_count,
    r.months_since_first_purchase AS month_number,
    r.returning_customers,
    ROUND(100 * r.returning_customers/sfpm.customer_count, 2) AS retention_rate_percentage
FROM   
    retention r
JOIN
    size_of_first_purchase_by_month sfpm
    ON sfpm.first_month = r.first_month
WHERE
    r.months_since_first_purchase <= 12
ORDER BY
    r.first_month,
    r.months_since_first_purchase;


-- Revenue Trends
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', i.invoice_date) AS month,
        ROUND(SUM(il.quantity * il.unit_price)::NUMERIC, 2) AS revenue
    FROM
        invoices i
    JOIN
        invoice_lines il
        ON i.invoice_no = il.invoice_no
    GROUP BY
        month
)

SELECT
    TO_CHAR(month, 'YYYY-MM') AS month, -- to string, e.g. 2025-03
    revenue AS monthly_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::NUMERIC,2) AS running_total, -- cum sum
    ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month))/NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS monthly_growth_percentage -- compare to previous row, null to avoid zero percentage error
FROM
    monthly_revenue
ORDER BY 
    month;