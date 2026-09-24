-- ============================================================
-- SAKUMAYA DIGITAL BANKING ANALYTICS
-- 06 — CARDS & CREDIT UTILIZATION ANALYSIS
--
-- Business Questions:
-- D30. Card count by type and status
-- D31. Card active/blocked/expired proportion
-- D32. Credit limit and outstanding for credit cards
-- D33. Aggregate credit utilization
-- D34. Utilization / outstanding by segment
-- D35. Card status by account tier / customer segment
--
-- Database schema: sakumaya
-- ============================================================

SET search_path TO sakumaya;


-- ============================================================
-- D30. CARD DISTRIBUTION BY TYPE & STATUS
-- ============================================================

SELECT
    card_type,
    status,
    COUNT(*) AS card_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS card_percentage
FROM cards
GROUP BY
    card_type,
    status
ORDER BY
    card_type,
    card_count DESC;


-- ============================================================
-- D31. CARD STATUS DISTRIBUTION
-- ============================================================

SELECT
    status,
    COUNT(*) AS card_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS card_percentage
FROM cards
GROUP BY status
ORDER BY card_count DESC;


-- ============================================================
-- D32. CREDIT CARD PORTFOLIO
-- ============================================================

SELECT
    COUNT(*) AS credit_card_count,
    SUM(credit_limit_idr) AS total_credit_limit_idr,
    SUM(outstanding_idr) AS total_outstanding_idr,
    ROUND(AVG(credit_limit_idr), 0) AS avg_credit_limit_idr,
    ROUND(AVG(outstanding_idr), 0) AS avg_outstanding_idr
FROM cards
WHERE card_type = 'credit'
  AND credit_limit_idr > 0;


-- ============================================================
-- D33. AGGREGATE CREDIT UTILIZATION
--
-- Formula:
-- SUM(outstanding) / SUM(credit_limit)
--
-- Only credit cards with a valid positive limit are included.
-- ============================================================

SELECT
    COUNT(*) AS eligible_credit_cards,
    SUM(credit_limit_idr) AS total_credit_limit_idr,
    SUM(outstanding_idr) AS total_outstanding_idr,
    ROUND(
        SUM(outstanding_idr) * 100.0
        / NULLIF(SUM(credit_limit_idr), 0),
        2
    ) AS credit_utilization_pct
FROM cards
WHERE card_type = 'credit'
  AND credit_limit_idr > 0;


-- ============================================================
-- D34A. CREDIT UTILIZATION BY CARD STATUS
-- ============================================================

SELECT
    status,
    COUNT(*) AS credit_card_count,
    SUM(credit_limit_idr) AS total_credit_limit_idr,
    SUM(outstanding_idr) AS total_outstanding_idr,
    ROUND(
        SUM(outstanding_idr) * 100.0
        / NULLIF(SUM(credit_limit_idr), 0),
        2
    ) AS credit_utilization_pct
FROM cards
WHERE card_type = 'credit'
  AND credit_limit_idr > 0
GROUP BY status
ORDER BY credit_utilization_pct DESC;


-- ============================================================
-- D34B. CREDIT UTILIZATION BY ACCOUNT TIER
-- ============================================================

SELECT
    a.tier,
    COUNT(c.card_id) AS credit_card_count,
    SUM(c.credit_limit_idr) AS total_credit_limit_idr,
    SUM(c.outstanding_idr) AS total_outstanding_idr,
    ROUND(
        SUM(c.outstanding_idr) * 100.0
        / NULLIF(SUM(c.credit_limit_idr), 0),
        2
    ) AS credit_utilization_pct,
    ROUND(
        AVG(c.outstanding_idr),
        0
    ) AS avg_outstanding_idr
FROM cards c
JOIN accounts a
    ON a.account_id = c.account_id
WHERE c.card_type = 'credit'
  AND c.credit_limit_idr > 0
GROUP BY a.tier
ORDER BY credit_utilization_pct DESC;


-- ============================================================
-- D34C. CREDIT UTILIZATION BY CUSTOMER KYC STATUS
-- ============================================================

SELECT
    cu.kyc_status,
    COUNT(c.card_id) AS credit_card_count,
    SUM(c.credit_limit_idr) AS total_credit_limit_idr,
    SUM(c.outstanding_idr) AS total_outstanding_idr,
    ROUND(
        SUM(c.outstanding_idr) * 100.0
        / NULLIF(SUM(c.credit_limit_idr), 0),
        2
    ) AS credit_utilization_pct
FROM cards c
JOIN customers cu
    ON cu.customer_id = c.customer_id
WHERE c.card_type = 'credit'
  AND c.credit_limit_idr > 0
GROUP BY cu.kyc_status
ORDER BY credit_utilization_pct DESC;


-- ============================================================
-- D34D. HIGH UTILIZATION CREDIT CARDS
--
-- Threshold:
-- utilization >= 70%
--
-- This is an analytical screening threshold, not a formal
-- credit-risk classification.
-- ============================================================

SELECT
    card_id,
    customer_id,
    account_id,
    credit_limit_idr,
    outstanding_idr,
    ROUND(
        outstanding_idr * 100.0
        / NULLIF(credit_limit_idr, 0),
        2
    ) AS utilization_pct,
    status
FROM cards
WHERE card_type = 'credit'
  AND credit_limit_idr > 0
  AND outstanding_idr * 1.0 / credit_limit_idr >= 0.70
ORDER BY utilization_pct DESC;


-- ============================================================
-- D35A. CARD STATUS BY ACCOUNT TIER
-- ============================================================

SELECT
    a.tier,
    c.status,
    COUNT(*) AS card_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (PARTITION BY a.tier),
        2
    ) AS status_percentage_within_tier
FROM cards c
JOIN accounts a
    ON a.account_id = c.account_id
GROUP BY
    a.tier,
    c.status
ORDER BY
    a.tier,
    card_count DESC;


-- ============================================================
-- D35B. CARD STATUS BY CUSTOMER KYC STATUS
-- ============================================================

SELECT
    cu.kyc_status,
    c.status,
    COUNT(*) AS card_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (PARTITION BY cu.kyc_status),
        2
    ) AS status_percentage_within_kyc
FROM cards c
JOIN customers cu
    ON cu.customer_id = c.customer_id
GROUP BY
    cu.kyc_status,
    c.status
ORDER BY
    cu.kyc_status,
    card_count DESC;


-- ============================================================
-- END OF CARDS & CREDIT UTILIZATION ANALYSIS
-- ============================================================
