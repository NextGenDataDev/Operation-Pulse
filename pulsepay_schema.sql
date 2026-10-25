-- Check the load. Expected: 155,079 / 20,025 / 10,000
SELECT 'transactions' AS tbl, COUNT(*) FROM transactions
UNION ALL SELECT 'support_interactions', COUNT(*) FROM support_interactions
UNION ALL SELECT 'customers', COUNT(*) FROM customers;

-- Q1: Status mix. The percentage uses a window function, so nothing is hard-coded.
SELECT transaction_status,
       COUNT(*) AS total_transactions,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM transactions
GROUP BY transaction_status
ORDER BY total_transactions DESC;

-- Q2: Failure rate by channel (JOIN + CASE).
SELECT c.channel_name,
       COUNT(*) AS total_tx,
       SUM(CASE WHEN t.transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_tx,
       ROUND(100.0 * SUM(CASE WHEN t.transaction_status = 'Failed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_pct
FROM transactions t
JOIN channels c ON t.channel_id = c.channel_id
GROUP BY c.channel_name
ORDER BY failure_rate_pct DESC;

-- Q3: Failure rate by city (where the transaction happened).
SELECT l.city,
       ROUND(100.0 * SUM(CASE WHEN t.transaction_status = 'Failed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_pct
FROM transactions t
JOIN locations l ON t.location_id = l.location_id
GROUP BY l.city
ORDER BY failure_rate_pct DESC;

-- Q4: Volume by customer segment. Cleans messy text with TRIM and INITCAP.
SELECT INITCAP(TRIM(cu.customer_segment)) AS segment,
       COUNT(*) AS total_transactions
FROM transactions t
JOIN customers cu ON t.customer_id = cu.customer_id
GROUP BY INITCAP(TRIM(cu.customer_segment))
ORDER BY total_transactions DESC;

-- Q5: Customer impact of failures.
SELECT t.transaction_status,
       COUNT(*) AS tickets,
       ROUND(AVG(s.customer_rating), 2) AS avg_rating,
       ROUND(AVG(s.resolution_time_minutes), 2) AS avg_resolution_min
FROM support_interactions s
JOIN transactions t ON s.transaction_id = t.transaction_id
GROUP BY t.transaction_status
ORDER BY avg_rating DESC;

-- Q6: Extreme transactions (subquery).
SELECT COUNT(*) AS transactions_above_1m,
       ROUND(100.0 * SUM(transaction_amount) / (SELECT SUM(transaction_amount) FROM transactions), 1) AS pct_of_total_value
FROM transactions
WHERE transaction_amount > 1000000;

-- Q7: Monthly failure trend (date function).
SELECT DATE_TRUNC('month', transaction_datetime)::date AS month,
       COUNT(*) AS total_tx,
       ROUND(100.0 * SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_pct
FROM transactions
GROUP BY 1
ORDER BY 1;