```sql
-- ============================================================
-- SAKUMAYA DIGITAL BANKING ANALYTICS
-- 01 — DATA QUALITY VALIDATION
--
-- Purpose:
-- Validate basic integrity of customers, accounts,
-- transactions, loans, and cards before analysis.
--
-- Database schema: sakumaya
-- ============================================================

SET search_path TO sakumaya;


-- ============================================================
-- 1. ROW COUNT
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'accounts', COUNT(*)
FROM accounts

UNION ALL

SELECT 'transactions', COUNT(*)
FROM transactions

UNION ALL

SELECT 'loans', COUNT(*)
FROM loans

UNION ALL

SELECT 'cards', COUNT(*)
FROM cards;


-- ============================================================
-- 2. PRIMARY KEY DUPLICATES
-- ============================================================

-- customers

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- accounts

SELECT
    account_id,
    COUNT(*) AS duplicate_count
FROM accounts
GROUP BY account_id
HAVING COUNT(*) > 1;


-- transactions

SELECT
    trx_id,
    COUNT(*) AS duplicate_count
FROM transactions
GROUP BY trx_id
HAVING COUNT(*) > 1;


-- loans

SELECT
    loan_id,
    COUNT(*) AS duplicate_count
FROM loans
GROUP BY loan_id
HAVING COUNT(*) > 1;


-- cards

SELECT
    card_id,
    COUNT(*) AS duplicate_count
FROM cards
GROUP BY card_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. FOREIGN KEY COVERAGE
-- ============================================================

-- accounts → customers

SELECT
    COUNT(*) AS orphan_accounts
FROM accounts a
LEFT JOIN customers c
    ON c.customer_id = a.customer_id
WHERE c.customer_id IS NULL;


-- transactions → accounts

SELECT
    COUNT(*) AS orphan_transactions
FROM transactions t
LEFT JOIN accounts a
    ON a.account_id = t.account_id
WHERE a.account_id IS NULL;


-- loans → customers

SELECT
    COUNT(*) AS orphan_loans
FROM loans l
LEFT JOIN customers c
    ON c.customer_id = l.customer_id
WHERE c.customer_id IS NULL;


-- cards → customers

SELECT
    COUNT(*) AS orphan_cards_customer
FROM cards ca
LEFT JOIN customers c
    ON c.customer_id = ca.customer_id
WHERE c.customer_id IS NULL;


-- cards → accounts

SELECT
    COUNT(*) AS orphan_cards_account
FROM cards ca
LEFT JOIN accounts a
    ON a.account_id = ca.account_id
WHERE a.account_id IS NULL;


-- ============================================================
-- 4. NULL CHECK
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE name IS NULL) AS null_name,
    COUNT(*) FILTER (WHERE city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE province IS NULL) AS null_province,
    COUNT(*) FILTER (WHERE dob IS NULL) AS null_dob,
    COUNT(*) FILTER (WHERE gender IS NULL) AS null_gender,
    COUNT(*) FILTER (WHERE kyc_status IS NULL) AS null_kyc_status,
    COUNT(*) FILTER (WHERE registration_date IS NULL) AS null_registration_date
FROM customers;


SELECT
    COUNT(*) FILTER (WHERE account_id IS NULL) AS null_account_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE account_number IS NULL) AS null_account_number,
    COUNT(*) FILTER (WHERE account_type IS NULL) AS null_account_type,
    COUNT(*) FILTER (WHERE balance_idr IS NULL) AS null_balance,
    COUNT(*) FILTER (WHERE created_date IS NULL) AS null_created_date,
    COUNT(*) FILTER (WHERE status IS NULL) AS null_status,
    COUNT(*) FILTER (WHERE tier IS NULL) AS null_tier
FROM accounts;


SELECT
    COUNT(*) FILTER (WHERE trx_id IS NULL) AS null_trx_id,
    COUNT(*) FILTER (WHERE account_id IS NULL) AS null_account_id,
    COUNT(*) FILTER (WHERE trx_type IS NULL) AS null_trx_type,
    COUNT(*) FILTER (WHERE amount_idr IS NULL) AS null_amount,
    COUNT(*) FILTER (WHERE trx_date IS NULL) AS null_trx_date,
    COUNT(*) FILTER (WHERE status IS NULL) AS null_status,
    COUNT(*) FILTER (WHERE channel IS NULL) AS null_channel
FROM transactions;


SELECT
    COUNT(*) FILTER (WHERE loan_id IS NULL) AS null_loan_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE loan_type IS NULL) AS null_loan_type,
    COUNT(*) FILTER (WHERE principal_idr IS NULL) AS null_principal,
    COUNT(*) FILTER (WHERE status IS NULL) AS null_status,
    COUNT(*) FILTER (WHERE due_date IS NULL) AS null_due_date
FROM loans;


SELECT
    COUNT(*) FILTER (WHERE card_id IS NULL) AS null_card_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE account_id IS NULL) AS null_account_id,
    COUNT(*) FILTER (WHERE card_type IS NULL) AS null_card_type,
    COUNT(*) FILTER (WHERE status IS NULL) AS null_status
FROM cards;


-- ============================================================
-- 5. VALID CATEGORY / STATUS CHECKS
-- ============================================================

-- Customer KYC

SELECT DISTINCT
    kyc_status
FROM customers
ORDER BY kyc_status;


-- Account status

SELECT DISTINCT
    status
FROM accounts
ORDER BY status;


-- Account type

SELECT DISTINCT
    account_type
FROM accounts
ORDER BY account_type;


-- Account tier

SELECT DISTINCT
    tier
FROM accounts
ORDER BY tier;


-- Transaction status

SELECT DISTINCT
    status
FROM transactions
ORDER BY status;


-- Transaction type

SELECT DISTINCT
    trx_type
FROM transactions
ORDER BY trx_type;


-- Transaction channel

SELECT DISTINCT
    channel
FROM transactions
ORDER BY channel;


-- Loan status

SELECT DISTINCT
    status
FROM loans
ORDER BY status;


-- Loan type

SELECT DISTINCT
    loan_type
FROM loans
ORDER BY loan_type;


-- Card type

SELECT DISTINCT
    card_type
FROM cards
ORDER BY card_type;


-- Card status

SELECT DISTINCT
    status
FROM cards
ORDER BY status;


-- ============================================================
-- 6. DATE VALIDATION
-- ============================================================

-- Account should not be created before customer registration

SELECT
    a.account_id,
    a.customer_id,
    c.registration_date,
    a.created_date
FROM accounts a
JOIN customers c
    ON c.customer_id = a.customer_id
WHERE a.created_date < c.registration_date;


-- ============================================================
-- 7. LOAN & KYC CONSISTENCY
-- Loans are documented as belonging to verified customers.

-- ============================================================

SELECT
    l.loan_id,
    l.customer_id,
    c.kyc_status
FROM loans l
JOIN customers c
    ON c.customer_id = l.customer_id
WHERE c.kyc_status <> 'verified';


-- ============================================================
-- 8. CARD DATA CONSISTENCY
-- credit_limit_idr and outstanding_idr are relevant
-- to credit cards.

-- Non-credit cards with credit limit

-- ============================================================

SELECT
    card_id,
    card_type,
    credit_limit_idr,
    outstanding_idr
FROM cards
WHERE card_type <> 'credit'
  AND (
      credit_limit_idr IS NOT NULL
      OR outstanding_idr IS NOT NULL
  );


-- Credit cards without a valid credit limit

SELECT
    card_id,
    card_type,
    credit_limit_idr,
    outstanding_idr
FROM cards
WHERE card_type = 'credit'
  AND (
      credit_limit_idr IS NULL
      OR credit_limit_idr <= 0
  );


-- ============================================================
-- 9. LOAN STATUS / OUTSTANDING CONSISTENCY
-- ============================================================

SELECT
    loan_id,
    status,
    outstanding_idr
FROM loans
WHERE status = 'paid_off'
  AND outstanding_idr > 0;


-- ============================================================
-- 10. TRANSACTION AMOUNT VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS negative_amount_count
FROM transactions
WHERE amount_idr < 0;


-- Zero-value transactions

SELECT
    COUNT(*) AS zero_amount_count
FROM transactions
WHERE amount_idr = 0;


-- ============================================================
-- 11. TRANSACTION DUPLICATE CHECK
-- Potential duplicate based on:
-- account + date + time + amount + transaction type
-- This is an investigative check, not proof of duplication.
-- ============================================================

SELECT
    account_id,
    trx_date,
    trx_time,
    amount_idr,
    trx_type,
    COUNT(*) AS occurrence_count
FROM transactions
GROUP BY
    account_id,
    trx_date,
    trx_time,
    amount_idr,
    trx_type
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;


-- ============================================================
-- 12. DATE RANGE CHECK
-- ============================================================

SELECT
    MIN(registration_date) AS min_registration_date,
    MAX(registration_date) AS max_registration_date
FROM customers;


SELECT
    MIN(trx_date) AS min_trx_date,
    MAX(trx_date) AS max_trx_date
FROM transactions;


SELECT
    MIN(disbursement_date) AS min_disbursement_date,
    MAX(disbursement_date) AS max_disbursement_date
FROM loans;


-- ============================================================
-- END OF DATA QUALITY VALIDATION
-- ============================================================
```
