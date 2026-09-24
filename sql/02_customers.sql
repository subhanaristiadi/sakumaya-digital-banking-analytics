-- ============================================================
-- SAKUMAYA DIGITAL BANKING ANALYTICS
-- 02 — CUSTOMER & KYC ANALYSIS
--
-- Business Questions:
-- D01. Customer count & percentage by KYC status
-- D02. Overall KYC verification rate
-- D03. Verification rate by province
-- D04. Customer profile by KYC status
-- D05. Referral vs direct signup
--
-- Database schema: sakumaya
-- ============================================================

SET search_path TO sakumaya;


-- ============================================================
-- D01. CUSTOMER DISTRIBUTION BY KYC STATUS
-- ============================================================

SELECT
    kyc_status,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM customers
GROUP BY kyc_status
ORDER BY customer_count DESC;


-- ============================================================
-- D02. OVERALL KYC VERIFICATION RATE
-- ============================================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE kyc_status = 'verified') AS verified_customers,
    ROUND(
        COUNT(*) FILTER (WHERE kyc_status = 'verified') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS verification_rate_pct
FROM customers;


-- ============================================================
-- D03. KYC VERIFICATION RATE BY PROVINCE
-- ============================================================

SELECT
    province,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE kyc_status = 'verified') AS verified_customers,
    ROUND(
        COUNT(*) FILTER (WHERE kyc_status = 'verified') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS verification_rate_pct
FROM customers
GROUP BY province
ORDER BY verification_rate_pct DESC;


-- ============================================================
-- D04. CUSTOMER PROFILE BY KYC STATUS
-- ============================================================

SELECT
    kyc_status,
    COUNT(*) AS customer_count,
    COUNT(*) FILTER (WHERE gender = 'Male') AS male_count,
    COUNT(*) FILTER (WHERE gender = 'Female') AS female_count,
    ROUND(AVG(
        EXTRACT(YEAR FROM CURRENT_DATE)
        - EXTRACT(YEAR FROM dob)
    ), 1) AS avg_age_approx,
    COUNT(DISTINCT city) AS city_count,
    MIN(registration_date) AS first_registration,
    MAX(registration_date) AS last_registration
FROM customers
GROUP BY kyc_status
ORDER BY customer_count DESC;


-- ============================================================
-- D05. REFERRAL VS DIRECT SIGNUP
-- ============================================================

SELECT
    CASE
        WHEN referral_code IS NULL THEN 'Direct Signup'
        ELSE 'Referral'
    END AS acquisition_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM customers
GROUP BY
    CASE
        WHEN referral_code IS NULL THEN 'Direct Signup'
        ELSE 'Referral'
    END
ORDER BY customer_count DESC;


-- ============================================================
-- END OF CUSTOMER & KYC ANALYSIS
-- ============================================================
