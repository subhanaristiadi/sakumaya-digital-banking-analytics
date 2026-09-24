-- ============================================================
-- SAKUMAYA DIGITAL BANKING ANALYTICS
-- 03 — ACCOUNT, TIER & AUM ANALYSIS
--
-- Business Questions:
-- D07. Account distribution by type, status, and tier
-- D08. Average, median, and total balance by tier
-- D09. AUM proxy and contribution by tier/account type
-- D10. Balance comparison across tiers
-- D11. Customers with more than one account
-- D12. Dormant/closed account concentration
--
-- Database schema: sakumaya
-- ============================================================

SET search_path TO sakumaya;


-- ============================================================
-- D07. ACCOUNT DISTRIBUTION
-- ============================================================

SELECT
    account_type,
    status,
    tier,
    COUNT(*) AS account_count
FROM accounts
GROUP BY
    account_type,
    status,
    tier
ORDER BY
    account_type,
    status,
    tier;


-- ============================================================
-- D08. BALANCE BY TIER
-- ============================================================

SELECT
    tier,
    COUNT(*) AS account_count,
    ROUND(AVG(balance_idr), 0) AS avg_balance_idr,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY balance_idr),
        0
    ) AS median_balance_idr,
    SUM(balance_idr) AS total_balance_idr
FROM accounts
GROUP BY tier
ORDER BY total_balance_idr DESC;


-- ============================================================
-- D09A. AUM PROXY — ACTIVE ACCOUNTS
--
-- Definition:
-- AUM proxy = SUM(balance_idr) for active accounts.
-- This is a balance-based proxy, not formal regulatory AUM.
-- ============================================================

SELECT
    COUNT(*) AS active_account_count,
    SUM(balance_idr) AS aum_proxy_idr,
    ROUND(AVG(balance_idr), 0) AS avg_active_account_balance_idr
FROM accounts
WHERE status = 'active';


-- ============================================================
-- D09B. AUM PROXY CONTRIBUTION BY TIER
-- ============================================================

SELECT
    tier,
    COUNT(*) AS active_account_count,
    SUM(balance_idr) AS balance_idr,
    ROUND(
        SUM(balance_idr) * 100.0
        / NULLIF(
            SUM(SUM(balance_idr)) OVER (),
            0
        ),
        2
    ) AS aum_contribution_pct
FROM accounts
WHERE status = 'active'
GROUP BY tier
ORDER BY balance_idr DESC;


-- ============================================================
-- D09C. AUM PROXY CONTRIBUTION BY ACCOUNT TYPE
-- ============================================================

SELECT
    account_type,
    COUNT(*) AS active_account_count,
    SUM(balance_idr) AS balance_idr,
    ROUND(
        SUM(balance_idr) * 100.0
        / NULLIF(
            SUM(SUM(balance_idr)) OVER (),
            0
        ),
        2
    ) AS aum_contribution_pct
FROM accounts
WHERE status = 'active'
GROUP BY account_type
ORDER BY balance_idr DESC;


-- ============================================================
-- D10. BALANCE COMPARISON ACROSS TIERS
-- ============================================================

SELECT
    tier,
    COUNT(*) AS account_count,
    ROUND(AVG(balance_idr), 0) AS avg_balance_idr,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY balance_idr),
        0
    ) AS median_balance_idr,
    MIN(balance_idr) AS min_balance_idr,
    MAX(balance_idr) AS max_balance_idr
FROM accounts
GROUP BY tier
ORDER BY
    CASE tier
        WHEN 'basic' THEN 1
        WHEN 'silver' THEN 2
        WHEN 'gold' THEN 3
        WHEN 'platinum' THEN 4
    END;


-- ============================================================
-- D11. CUSTOMERS WITH MORE THAN ONE ACCOUNT
-- ============================================================

SELECT
    COUNT(*) AS customers_with_multiple_accounts
FROM (
    SELECT
        customer_id
    FROM accounts
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS multi_account_customers;


-- Detail of account ownership distribution
SELECT
    account_count,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS account_count
    FROM accounts
    GROUP BY customer_id
) AS customer_accounts
GROUP BY account_count
ORDER BY account_count;


-- ============================================================
-- D12A. DORMANT / CLOSED CONCENTRATION BY TIER
-- ============================================================

SELECT
    tier,
    COUNT(*) FILTER (
        WHERE status IN ('dormant', 'closed')
    ) AS inactive_account_count,
    COUNT(*) AS total_account_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE status IN ('dormant', 'closed')
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS inactive_rate_pct
FROM accounts
GROUP BY tier
ORDER BY inactive_rate_pct DESC;


-- ============================================================
-- D12B. DORMANT / CLOSED CONCENTRATION BY ACCOUNT TYPE
-- ============================================================

SELECT
    account_type,
    COUNT(*) FILTER (
        WHERE status IN ('dormant', 'closed')
    ) AS inactive_account_count,
    COUNT(*) AS total_account_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE status IN ('dormant', 'closed')
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS inactive_rate_pct
FROM accounts
GROUP BY account_type
ORDER BY inactive_rate_pct DESC;


-- ============================================================
-- D12C. DORMANT / CLOSED CONCENTRATION BY CITY
-- ============================================================

SELECT
    c.city,
    COUNT(*) FILTER (
        WHERE a.status IN ('dormant', 'closed')
    ) AS inactive_account_count,
    COUNT(*) AS total_account_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE a.status IN ('dormant', 'closed')
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS inactive_rate_pct
FROM accounts a
JOIN customers c
    ON c.customer_id = a.customer_id
GROUP BY c.city
ORDER BY inactive_rate_pct DESC;


-- ============================================================
-- END OF ACCOUNT, TIER & AUM ANALYSIS
-- ============================================================
