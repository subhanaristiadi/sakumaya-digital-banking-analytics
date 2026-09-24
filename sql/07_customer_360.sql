-- ============================================================
-- SAKUMAYA DIGITAL BANKING ANALYTICS
-- 07 — CUSTOMER 360 & CROSS-DOMAIN ANALYSIS
--
-- Business Questions:
-- D06. Referral vs direct signup comparison
-- D36. Customer value across balance, activity, cards, loans
-- D37. Engagement & balance by customer tier
-- D38. High-balance vs high-activity customers
-- D39. Borrower vs verified non-borrower comparison
--
-- Principle:
-- Aggregate each domain to customer grain first.
-- This prevents row multiplication across one-to-many tables.
--
-- Database schema: sakumaya
-- ============================================================

SET search_path TO sakumaya;


-- ============================================================
-- D06. REFERRAL VS DIRECT SIGNUP
--
-- Compare customer profile, account ownership,
-- transaction activity, and loan ownership.
-- ============================================================

WITH account_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS account_count,
        SUM(balance_idr) AS total_balance_idr
    FROM accounts
    GROUP BY customer_id
),

transaction_summary AS (
    SELECT
        a.customer_id,
        COUNT(t.trx_id) AS transaction_volume,
        SUM(t.amount_idr) AS transaction_value_idr
    FROM accounts a
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'success'
    GROUP BY a.customer_id
),

loan_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS loan_count,
        SUM(outstanding_idr) AS total_outstanding_idr
    FROM loans
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN c.referral_code IS NULL THEN 'Direct Signup'
        ELSE 'Referral'
    END AS acquisition_type,
    COUNT(*) AS customer_count,
    ROUND(AVG(
        EXTRACT(YEAR FROM CURRENT_DATE)
        - EXTRACT(YEAR FROM c.dob)
    ), 1) AS avg_age_approx,
    COUNT(*) FILTER (
        WHERE c.kyc_status = 'verified'
    ) AS verified_customer_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE c.kyc_status = 'verified'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS verification_rate_pct,
    ROUND(AVG(
        COALESCE(a.account_count, 0)
    ), 2) AS avg_accounts_per_customer,
    ROUND(AVG(
        COALESCE(a.total_balance_idr, 0)
    ), 0) AS avg_total_balance_idr,
    ROUND(AVG(
        COALESCE(t.transaction_volume, 0)
    ), 2) AS avg_transaction_volume,
    ROUND(AVG(
        COALESCE(t.transaction_value_idr, 0)
    ), 0) AS avg_transaction_value_idr,
    COUNT(l.customer_id) AS borrower_count,
    ROUND(
        COUNT(l.customer_id) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS borrower_rate_pct
FROM customers c
LEFT JOIN account_summary a
    ON a.customer_id = c.customer_id
LEFT JOIN transaction_summary t
    ON t.customer_id = c.customer_id
LEFT JOIN loan_summary l
    ON l.customer_id = c.customer_id
GROUP BY
    CASE
        WHEN c.referral_code IS NULL THEN 'Direct Signup'
        ELSE 'Referral'
    END
ORDER BY customer_count DESC;


-- ============================================================
-- D36. CUSTOMER 360 PROFILE
--
-- One row = one customer.
--
-- Metrics:
-- - account ownership
-- - balance
-- - transaction activity
-- - card ownership
-- - loan exposure
-- ============================================================

WITH account_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS account_count,
        SUM(balance_idr) AS total_balance_idr
    FROM accounts
    GROUP BY customer_id
),

transaction_summary AS (
    SELECT
        a.customer_id,
        COUNT(t.trx_id) AS transaction_volume,
        SUM(t.amount_idr) AS transaction_value_idr
    FROM accounts a
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'success'
    GROUP BY a.customer_id
),

card_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS card_count,
        COUNT(*) FILTER (
            WHERE card_type = 'credit'
        ) AS credit_card_count,
        SUM(
            CASE
                WHEN card_type = 'credit'
                THEN COALESCE(outstanding_idr, 0)
                ELSE 0
            END
        ) AS credit_outstanding_idr
    FROM cards
    GROUP BY customer_id
),

loan_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS loan_count,
        SUM(principal_idr) AS total_principal_idr,
        SUM(outstanding_idr) AS total_outstanding_idr,
        COUNT(*) FILTER (
            WHERE status IN ('overdue', 'written_off')
        ) AS at_risk_loan_count
    FROM loans
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.kyc_status,

    COALESCE(a.account_count, 0) AS account_count,
    COALESCE(a.total_balance_idr, 0) AS total_balance_idr,

    COALESCE(t.transaction_volume, 0) AS transaction_volume,
    COALESCE(t.transaction_value_idr, 0) AS transaction_value_idr,

    COALESCE(cs.card_count, 0) AS card_count,
    COALESCE(cs.credit_card_count, 0) AS credit_card_count,
    COALESCE(cs.credit_outstanding_idr, 0) AS credit_outstanding_idr,

    COALESCE(l.loan_count, 0) AS loan_count,
    COALESCE(l.total_principal_idr, 0) AS total_principal_idr,
    COALESCE(l.total_outstanding_idr, 0) AS total_outstanding_idr,
    COALESCE(l.at_risk_loan_count, 0) AS at_risk_loan_count

FROM customers c
LEFT JOIN account_summary a
    ON a.customer_id = c.customer_id
LEFT JOIN transaction_summary t
    ON t.customer_id = c.customer_id
LEFT JOIN card_summary cs
    ON cs.customer_id = c.customer_id
LEFT JOIN loan_summary l
    ON l.customer_id = c.customer_id
ORDER BY total_balance_idr DESC;


-- ============================================================
-- D37. BALANCE & ENGAGEMENT BY CUSTOMER TIER
--
-- Customer tier definition:
-- highest account tier owned by the customer.
--
-- Tier hierarchy:
-- basic < silver < gold < platinum
-- ============================================================

WITH customer_tier AS (
    SELECT
        customer_id,
        CASE MAX(
            CASE tier
                WHEN 'basic' THEN 1
                WHEN 'silver' THEN 2
                WHEN 'gold' THEN 3
                WHEN 'platinum' THEN 4
            END
        )
            WHEN 1 THEN 'basic'
            WHEN 2 THEN 'silver'
            WHEN 3 THEN 'gold'
            WHEN 4 THEN 'platinum'
        END AS highest_tier
    FROM accounts
    GROUP BY customer_id
),

account_summary AS (
    SELECT
        customer_id,
        SUM(balance_idr) AS total_balance_idr
    FROM accounts
    GROUP BY customer_id
),

transaction_summary AS (
    SELECT
        a.customer_id,
        COUNT(t.trx_id) AS transaction_volume,
        SUM(t.amount_idr) AS transaction_value_idr
    FROM accounts a
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'success'
    GROUP BY a.customer_id
)

SELECT
    ct.highest_tier,
    COUNT(*) AS customer_count,
    ROUND(
        AVG(COALESCE(a.total_balance_idr, 0)),
        0
    ) AS avg_balance_idr,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY COALESCE(a.total_balance_idr, 0)
        ),
        0
    ) AS median_balance_idr,
    ROUND(
        AVG(COALESCE(t.transaction_volume, 0)),
        2
    ) AS avg_transaction_volume,
    ROUND(
        AVG(COALESCE(t.transaction_value_idr, 0)),
        0
    ) AS avg_transaction_value_idr
FROM customer_tier ct
LEFT JOIN account_summary a
    ON a.customer_id = ct.customer_id
LEFT JOIN transaction_summary t
    ON t.customer_id = ct.customer_id
GROUP BY ct.highest_tier
ORDER BY
    CASE ct.highest_tier
        WHEN 'basic' THEN 1
        WHEN 'silver' THEN 2
        WHEN 'gold' THEN 3
        WHEN 'platinum' THEN 4
    END;


-- ============================================================
-- D38. HIGH-BALANCE VS HIGH-ACTIVITY CUSTOMERS
--
-- Threshold:
-- P75 for total balance and transaction volume.
--
-- This creates four customer segments:
-- 1. High Balance / High Activity
-- 2. High Balance / Low Activity
-- 3. Low Balance / High Activity
-- 4. Low Balance / Low Activity
-- ============================================================

WITH account_summary AS (
    SELECT
        customer_id,
        SUM(balance_idr) AS total_balance_idr
    FROM accounts
    GROUP BY customer_id
),

transaction_summary AS (
    SELECT
        a.customer_id,
        COUNT(t.trx_id) AS transaction_volume
    FROM accounts a
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'success'
    GROUP BY a.customer_id
),

customer_metrics AS (
    SELECT
        c.customer_id,
        COALESCE(a.total_balance_idr, 0) AS total_balance_idr,
        COALESCE(t.transaction_volume, 0) AS transaction_volume
    FROM customers c
    LEFT JOIN account_summary a
        ON a.customer_id = c.customer_id
    LEFT JOIN transaction_summary t
        ON t.customer_id = c.customer_id
),

thresholds AS (
    SELECT
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (
            ORDER BY total_balance_idr
        ) AS balance_p75,
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (
            ORDER BY transaction_volume
        ) AS activity_p75
    FROM customer_metrics
)

SELECT
    CASE
        WHEN cm.total_balance_idr >= th.balance_p75
         AND cm.transaction_volume >= th.activity_p75
            THEN 'High Balance / High Activity'

        WHEN cm.total_balance_idr >= th.balance_p75
         AND cm.transaction_volume < th.activity_p75
            THEN 'High Balance / Low Activity'

        WHEN cm.total_balance_idr < th.balance_p75
         AND cm.transaction_volume >= th.activity_p75
            THEN 'Low Balance / High Activity'

        ELSE 'Low Balance / Low Activity'
    END AS customer_segment,

    COUNT(*) AS customer_count,
    ROUND(AVG(cm.total_balance_idr), 0) AS avg_balance_idr,
    ROUND(AVG(cm.transaction_volume), 2) AS avg_transaction_volume

FROM customer_metrics cm
CROSS JOIN thresholds th

GROUP BY
    CASE
        WHEN cm.total_balance_idr >= th.balance_p75
         AND cm.transaction_volume >= th.activity_p75
            THEN 'High Balance / High Activity'

        WHEN cm.total_balance_idr >= th.balance_p75
         AND cm.transaction_volume < th.activity_p75
            THEN 'High Balance / Low Activity'

        WHEN cm.total_balance_idr < th.balance_p75
         AND cm.transaction_volume >= th.activity_p75
            THEN 'Low Balance / High Activity'

        ELSE 'Low Balance / Low Activity'
    END

ORDER BY customer_count DESC;


-- ============================================================
-- D39. BORROWER VS VERIFIED NON-BORROWER
--
-- Population:
-- verified customers only.
--
-- Borrower:
-- customer with at least one loan.
--
-- Non-borrower:
-- verified customer with no loan.
-- ============================================================

WITH account_summary AS (
    SELECT
        customer_id,
        SUM(balance_idr) AS total_balance_idr
    FROM accounts
    GROUP BY customer_id
),

transaction_summary AS (
    SELECT
        a.customer_id,
        COUNT(t.trx_id) AS transaction_volume,
        SUM(t.amount_idr) AS transaction_value_idr
    FROM accounts a
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'success'
    GROUP BY a.customer_id
),

loan_customers AS (
    SELECT DISTINCT
        customer_id
    FROM loans
)

SELECT
    CASE
        WHEN lc.customer_id IS NOT NULL
            THEN 'Borrower'
        ELSE 'Verified Non-Borrower'
    END AS customer_group,

    COUNT(*) AS customer_count,

    ROUND(
        AVG(COALESCE(a.total_balance_idr, 0)),
        0
    ) AS avg_balance_idr,

    ROUND(
        AVG(COALESCE(t.transaction_volume, 0)),
        2
    ) AS avg_transaction_volume,

    ROUND(
        AVG(COALESCE(t.transaction_value_idr, 0)),
        0
    ) AS avg_transaction_value_idr

FROM customers c

LEFT JOIN account_summary a
    ON a.customer_id = c.customer_id

LEFT JOIN transaction_summary t
    ON t.customer_id = c.customer_id

LEFT JOIN loan_customers lc
    ON lc.customer_id = c.customer_id

WHERE c.kyc_status = 'verified'

GROUP BY
    CASE
        WHEN lc.customer_id IS NOT NULL
            THEN 'Borrower'
        ELSE 'Verified Non-Borrower'
    END

ORDER BY customer_group;


-- ============================================================
-- EXECUTIVE KPI SNAPSHOT
--
-- One-row summary for dashboard preparation.
-- ============================================================

WITH account_kpi AS (
    SELECT
        COUNT(DISTINCT customer_id) AS customers_with_account,
        SUM(balance_idr) AS total_balance_idr
    FROM accounts
),

transaction_kpi AS (
    SELECT
        COUNT(*) AS successful_transaction_volume,
        SUM(amount_idr) AS successful_transaction_value_idr
    FROM transactions
    WHERE status = 'success'
),

loan_kpi AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(outstanding_idr) AS total_loan_outstanding_idr
    FROM loans
),

card_kpi AS (
    SELECT
        COUNT(*) AS total_cards,
        COUNT(*) FILTER (
            WHERE card_type = 'credit'
        ) AS total_credit_cards
    FROM cards
)

SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,

    (SELECT COUNT(*)
     FROM customers
     WHERE kyc_status = 'verified') AS verified_customers,

    ROUND(
        (SELECT COUNT(*)
         FROM customers
         WHERE kyc_status = 'verified') * 100.0
        / NULLIF(
            (SELECT COUNT(*) FROM customers),
            0
        ),
        2
    ) AS kyc_verification_rate_pct,

    ak.customers_with_account,
    ak.total_balance_idr,

    tk.successful_transaction_volume,
    tk.successful_transaction_value_idr,

    lk.total_loans,
    lk.total_loan_outstanding_idr,

    ck.total_cards,
    ck.total_credit_cards

FROM account_kpi ak
CROSS JOIN transaction_kpi tk
CROSS JOIN loan_kpi lk
CROSS JOIN card_kpi ck;


-- ============================================================
-- END OF CUSTOMER 360 & CROSS-DOMAIN ANALYSIS
-- ============================================================
