-- ============================================================
-- SECTION D — LOAN & CREDIT RISK
-- Population: seluruh loans (n = 300), snapshot outstanding_idr per data pull.
-- Grain: 1 row = 1 loan (1 customer bisa punya >1 loan -- perlu dicek).
-- Definisi risiko yang dipakai di sini: "at-risk portfolio"
-- = status IN ('overdue','written_off').
-- Denominator & definisi harus dinyatakan eksplisit setiap kali dipakai.
-- ============================================================

SET search_path TO sakumaya;

-- ------------------------------------------------------------
-- D22. Jumlah & nilai pinjaman menurut loan_type dan status
-- ------------------------------------------------------------

SELECT
    loan_type,
    status,
    COUNT(*) AS n_loans,
    SUM(principal_idr) AS total_principal_idr,
    SUM(outstanding_idr) AS total_outstanding_idr
FROM loans
GROUP BY loan_type, status
ORDER BY loan_type, status;


-- ------------------------------------------------------------
-- D23. Total outstanding portfolio & distribusi menurut loan_type
-- Denominator: total outstanding seluruh loan
-- ------------------------------------------------------------

WITH agg AS (
    SELECT
        loan_type,
        SUM(outstanding_idr) AS outstanding_idr
    FROM loans
    GROUP BY loan_type
)

SELECT
    loan_type,
    outstanding_idr,
    ROUND(
        100.0 * outstanding_idr / SUM(outstanding_idr) OVER (),
        2
    ) AS pct_of_portfolio
FROM agg
ORDER BY outstanding_idr DESC;

SELECT
    SUM(outstanding_idr) AS total_outstanding_portfolio_idr
FROM loans;


-- ------------------------------------------------------------
-- D24. Proporsi loan overdue dan written_off
-- Denominator: total loans (300)
-- ------------------------------------------------------------

SELECT
    status,
    COUNT(*) AS n_loans,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_loan_count,
    SUM(outstanding_idr) AS outstanding_idr,
    ROUND(
        100.0 * SUM(outstanding_idr)
        / SUM(SUM(outstanding_idr)) OVER (),
        2
    ) AS pct_of_outstanding_value
FROM loans
GROUP BY status
ORDER BY n_loans DESC;


-- ------------------------------------------------------------
-- D25. Loan type dengan overdue/write-off rate tertinggi
-- Rate = (overdue + written_off) / total loans pada loan_type
-- ------------------------------------------------------------

SELECT
    loan_type,
    COUNT(*) AS n_loans,
    COUNT(*) FILTER (
        WHERE status = 'overdue'
    ) AS n_overdue,
    COUNT(*) FILTER (
        WHERE status = 'written_off'
    ) AS n_written_off,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE status = 'overdue'
        ) / COUNT(*),
        2
    ) AS overdue_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE status = 'written_off'
        ) / COUNT(*),
        2
    ) AS write_off_rate_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE status IN ('overdue', 'written_off')
        ) / COUNT(*),
        2
    ) AS at_risk_rate_pct
FROM loans
GROUP BY loan_type
ORDER BY at_risk_rate_pct DESC;


-- ------------------------------------------------------------
-- D26. Keterkaitan interest_rate, tenure, principal,
--      customer segment dengan status pinjaman
-- Deskriptif, bukan uji signifikansi statistik/kausalitas.
-- ------------------------------------------------------------

SELECT
    status,
    COUNT(*) AS n_loans,
    ROUND(
        AVG(interest_rate_annual) * 100,
        2
    ) AS avg_interest_rate_pct,
    ROUND(
        AVG(tenure_months),
        1
    ) AS avg_tenure_months,
    ROUND(
        AVG(principal_idr),
        0
    ) AS avg_principal_idr,
    ROUND(
        AVG(monthly_installment_idr),
        0
    ) AS avg_installment_idr
FROM loans
GROUP BY status
ORDER BY n_loans DESC;


-- Customer segment (kyc_status, province) vs loan status

SELECT
    c.kyc_status,
    l.status,
    COUNT(*) AS n_loans,
    SUM(l.outstanding_idr) AS outstanding_idr
FROM loans l
JOIN customers c
    ON c.customer_id = l.customer_id
GROUP BY
    c.kyc_status,
    l.status
ORDER BY
    c.kyc_status,
    l.status;


-- ------------------------------------------------------------
-- D27. Distribusi outstanding balance untuk active loans
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS n_active_loans,
    ROUND(
        AVG(outstanding_idr),
        0
    ) AS avg_outstanding_idr,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY outstanding_idr)
        AS median_outstanding_idr,
    MIN(outstanding_idr) AS min_outstanding_idr,
    MAX(outstanding_idr) AS max_outstanding_idr,
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY outstanding_idr)
        AS p25_outstanding_idr,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY outstanding_idr)
        AS p75_outstanding_idr
FROM loans
WHERE status = 'active';


-- Bucketed distribution

SELECT
    WIDTH_BUCKET(
        outstanding_idr,
        0,
        200000000,
        10
    ) AS bucket,
    COUNT(*) AS n_loans,
    MIN(outstanding_idr) AS bucket_min,
    MAX(outstanding_idr) AS bucket_max
FROM loans
WHERE status = 'active'
GROUP BY 1
ORDER BY 1;


-- ------------------------------------------------------------
-- D28. Estimasi portfolio berisiko & denominator
-- Definisi risiko:
-- status IN ('overdue','written_off')
-- Denominator:
-- total outstanding seluruh loan
-- ------------------------------------------------------------

SELECT
    SUM(outstanding_idr) FILTER (
        WHERE status IN ('overdue', 'written_off')
    ) AS at_risk_outstanding_idr,
    SUM(outstanding_idr) AS total_outstanding_idr,
    ROUND(
        100.0 *
        SUM(outstanding_idr) FILTER (
            WHERE status IN ('overdue', 'written_off')
        )
        / SUM(outstanding_idr),
        2
    ) AS at_risk_pct_of_portfolio
FROM loans;


-- Versi lebih konservatif:
-- hanya overdue, tanpa written_off.

SELECT
    SUM(outstanding_idr) FILTER (
        WHERE status = 'overdue'
    ) AS overdue_outstanding_idr,
    SUM(outstanding_idr) FILTER (
        WHERE status = 'active'
    ) AS active_outstanding_idr,
    ROUND(
        100.0 *
        SUM(outstanding_idr) FILTER (
            WHERE status = 'overdue'
        )
        / NULLIF(
            SUM(outstanding_idr) FILTER (
                WHERE status IN ('active', 'overdue')
            ),
            0
        ),
        2
    ) AS overdue_pct_of_performing_book
FROM loans;


-- ------------------------------------------------------------
-- D29. Perbedaan aktivitas rekening/transaksi:
-- borrower vs verified customer tanpa loan
-- Population:
-- customer dengan kyc_status = 'verified'
-- ------------------------------------------------------------

WITH verified_cust AS (
    SELECT
        customer_id
    FROM customers
    WHERE kyc_status = 'verified'
),

borrower_flag AS (
    SELECT
        vc.customer_id,
        CASE
            WHEN l.customer_id IS NOT NULL
                THEN 'borrower'
            ELSE 'non_borrower'
        END AS segment
    FROM verified_cust vc
    LEFT JOIN (
        SELECT DISTINCT
            customer_id
        FROM loans
    ) l
        ON l.customer_id = vc.customer_id
),

acct_trx AS (
    SELECT
        a.customer_id,
        COUNT(DISTINCT a.account_id) AS n_accounts,
        SUM(a.balance_idr) AS total_balance,
        COUNT(t.trx_id) AS n_trx,
        COALESCE(
            SUM(t.amount_idr)
                FILTER (WHERE t.status = 'success'),
            0
        ) AS total_trx_value
    FROM accounts a
    LEFT JOIN transactions t
        ON t.account_id = a.account_id
    GROUP BY a.customer_id
)

SELECT
    bf.segment,
    COUNT(*) AS n_customers,
    ROUND(
        AVG(COALESCE(at.n_accounts, 0)),
        2
    ) AS avg_accounts,
    ROUND(
        AVG(COALESCE(at.total_balance, 0)),
        0
    ) AS avg_total_balance_idr,
    ROUND(
        AVG(COALESCE(at.n_trx, 0)),
        1
    ) AS avg_trx_count,
    ROUND(
        AVG(COALESCE(at.total_trx_value, 0)),
        0
    ) AS avg_trx_value_idr
FROM borrower_flag bf
LEFT JOIN acct_trx at
    ON at.customer_id = bf.customer_id
GROUP BY bf.segment;
