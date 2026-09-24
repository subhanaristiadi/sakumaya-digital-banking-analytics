-- ============================================================
-- SAKUMAYA DIGITAL BANKING ANALYTICS
-- 04 — TRANSACTION & USAGE ANALYSIS
--
-- Business Questions:
-- D13. Transaction volume & value by month
-- D14. Transaction trend by type, category, and channel
-- D15. Channel usage by count and value
-- D16. Merchant category by transaction value
-- D17. Overall success/failure rate
-- D18. Failure rate by channel, type, category, and month
-- D19. Unusual transaction patterns
-- D20. Most active customer/account segments
-- D21. Aggregate inflow vs outflow
--
-- Database schema: sakumaya
-- ============================================================

SET search_path TO sakumaya;


-- ============================================================
-- D13. TRANSACTION VOLUME & VALUE BY MONTH
-- ============================================================

SELECT
    DATE_TRUNC('month', trx_date)::date AS month,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr,
    ROUND(AVG(amount_idr), 0) AS avg_transaction_value_idr
FROM transactions
GROUP BY DATE_TRUNC('month', trx_date)
ORDER BY month;


-- ============================================================
-- D14A. TRANSACTION TREND BY TYPE
-- ============================================================

SELECT
    DATE_TRUNC('month', trx_date)::date AS month,
    trx_type,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr
FROM transactions
GROUP BY
    DATE_TRUNC('month', trx_date),
    trx_type
ORDER BY
    month,
    transaction_volume DESC;


-- ============================================================
-- D14B. TRANSACTION TREND BY MERCHANT CATEGORY
-- ============================================================

SELECT
    DATE_TRUNC('month', trx_date)::date AS month,
    merchant_category,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr
FROM transactions
GROUP BY
    DATE_TRUNC('month', trx_date),
    merchant_category
ORDER BY
    month,
    transaction_value_idr DESC;


-- ============================================================
-- D14C. TRANSACTION TREND BY CHANNEL
-- ============================================================

SELECT
    DATE_TRUNC('month', trx_date)::date AS month,
    channel,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr
FROM transactions
GROUP BY
    DATE_TRUNC('month', trx_date),
    channel
ORDER BY
    month,
    transaction_volume DESC;


-- ============================================================
-- D15. CHANNEL USAGE — COUNT & VALUE
-- ============================================================

SELECT
    channel,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS volume_share_pct,
    ROUND(
        SUM(amount_idr) * 100.0
        / NULLIF(SUM(SUM(amount_idr)) OVER (), 0),
        2
    ) AS value_share_pct
FROM transactions
GROUP BY channel
ORDER BY transaction_volume DESC;


-- ============================================================
-- D16. MERCHANT CATEGORY BY TRANSACTION VALUE
-- ============================================================

SELECT
    merchant_category,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr,
    ROUND(AVG(amount_idr), 0) AS avg_transaction_value_idr,
    ROUND(
        SUM(amount_idr) * 100.0
        / NULLIF(SUM(SUM(amount_idr)) OVER (), 0),
        2
    ) AS value_share_pct
FROM transactions
GROUP BY merchant_category
ORDER BY transaction_value_idr DESC;


-- ============================================================
-- D17. OVERALL TRANSACTION SUCCESS / FAILURE RATE
-- ============================================================

SELECT
    status,
    COUNT(*) AS transaction_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS transaction_rate_pct
FROM transactions
GROUP BY status
ORDER BY transaction_count DESC;


-- ============================================================
-- D18A. FAILURE RATE BY CHANNEL
-- ============================================================

SELECT
    channel,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_transactions,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'failed') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS failure_rate_pct
FROM transactions
GROUP BY channel
ORDER BY failure_rate_pct DESC;


-- ============================================================
-- D18B. FAILURE RATE BY TRANSACTION TYPE
-- ============================================================

SELECT
    trx_type,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_transactions,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'failed') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS failure_rate_pct
FROM transactions
GROUP BY trx_type
ORDER BY failure_rate_pct DESC;


-- ============================================================
-- D18C. FAILURE RATE BY MERCHANT CATEGORY
-- ============================================================

SELECT
    merchant_category,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_transactions,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'failed') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS failure_rate_pct
FROM transactions
GROUP BY merchant_category
ORDER BY failure_rate_pct DESC;


-- ============================================================
-- D18D. FAILURE RATE BY MONTH
-- ============================================================

SELECT
    DATE_TRUNC('month', trx_date)::date AS month,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_transactions,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'failed') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS failure_rate_pct
FROM transactions
GROUP BY DATE_TRUNC('month', trx_date)
ORDER BY month;


-- ============================================================
-- D19A. TRANSACTION AMOUNT DISTRIBUTION
-- ============================================================

SELECT
    COUNT(*) AS transaction_count,
    MIN(amount_idr) AS min_amount_idr,
    ROUND(AVG(amount_idr), 0) AS avg_amount_idr,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY amount_idr),
        0
    ) AS median_amount_idr,
    ROUND(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY amount_idr),
        0
    ) AS p95_amount_idr,
    MAX(amount_idr) AS max_amount_idr
FROM transactions;


-- ============================================================
-- D19B. TRANSACTIONS ABOVE P95
-- ============================================================

WITH transaction_threshold AS (
    SELECT
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY amount_idr) AS p95_amount
    FROM transactions
)
SELECT
    t.trx_id,
    t.account_id,
    t.trx_type,
    t.amount_idr,
    t.merchant_category,
    t.trx_date,
    t.trx_time,
    t.status,
    t.channel
FROM transactions t
CROSS JOIN transaction_threshold p
WHERE t.amount_idr > p.p95_amount
ORDER BY t.amount_idr DESC;


-- ============================================================
-- D19C. TRANSACTION PATTERN BY HOUR
-- ============================================================

SELECT
    EXTRACT(HOUR FROM trx_time) AS transaction_hour,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr,
    ROUND(AVG(amount_idr), 0) AS avg_transaction_value_idr
FROM transactions
GROUP BY EXTRACT(HOUR FROM trx_time)
ORDER BY transaction_hour;


-- ============================================================
-- D19D. TRANSACTION PATTERN BY MERCHANT CATEGORY
-- ============================================================

SELECT
    merchant_category,
    COUNT(*) AS transaction_volume,
    ROUND(AVG(amount_idr), 0) AS avg_transaction_value_idr,
    MIN(amount_idr) AS min_amount_idr,
    MAX(amount_idr) AS max_amount_idr
FROM transactions
GROUP BY merchant_category
ORDER BY transaction_volume DESC;


-- ============================================================
-- D20. MOST ACTIVE ACCOUNTS
-- ============================================================

SELECT
    account_id,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr,
    ROUND(AVG(amount_idr), 0) AS avg_transaction_value_idr
FROM transactions
GROUP BY account_id
ORDER BY transaction_volume DESC
LIMIT 20;


-- ============================================================
-- D20B. CUSTOMER ACTIVITY
--
-- Transactions are pre-aggregated by account first so that
-- customer-level metrics are not multiplied by account rows.
-- ============================================================

WITH account_activity AS (
    SELECT
        account_id,
        COUNT(*) AS transaction_volume,
        SUM(amount_idr) AS transaction_value_idr
    FROM transactions
    GROUP BY account_id
)
SELECT
    a.customer_id,
    COUNT(a.account_id) AS account_count,
    SUM(COALESCE(aa.transaction_volume, 0)) AS transaction_volume,
    SUM(COALESCE(aa.transaction_value_idr, 0)) AS transaction_value_idr
FROM accounts a
LEFT JOIN account_activity aa
    ON aa.account_id = a.account_id
GROUP BY a.customer_id
ORDER BY transaction_volume DESC
LIMIT 20;


-- ============================================================
-- D21. AGGREGATE INFLOW VS OUTFLOW
--
-- Inflow:
-- credit, transfer_in, top_up
--
-- Outflow:
-- debit, transfer_out
-- ============================================================

SELECT
    CASE
        WHEN trx_type IN ('credit', 'transfer_in', 'top_up')
            THEN 'Inflow'
        WHEN trx_type IN ('debit', 'transfer_out')
            THEN 'Outflow'
    END AS flow_type,
    COUNT(*) AS transaction_volume,
    SUM(amount_idr) AS transaction_value_idr,
    ROUND(AVG(amount_idr), 0) AS avg_transaction_value_idr
FROM transactions
GROUP BY
    CASE
        WHEN trx_type IN ('credit', 'transfer_in', 'top_up')
            THEN 'Inflow'
        WHEN trx_type IN ('debit', 'transfer_out')
            THEN 'Outflow'
    END
ORDER BY transaction_value_idr DESC;


-- ============================================================
-- END OF TRANSACTION & USAGE ANALYSIS
-- ============================================================
