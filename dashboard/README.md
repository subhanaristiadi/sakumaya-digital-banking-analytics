# Sakumaya Financial Health Dashboard

Dashboard ini dirancang sebagai executive view untuk memantau kesehatan bisnis Sakumaya berdasarkan customer, account, transaction, loan, dan card data.

## Dashboard Objective

Memberikan ringkasan kondisi bisnis melalui:

- Customer & KYC
- Account & balance
- Transaction activity
- Loan portfolio & credit risk
- Credit card utilization

## Dashboard Structure

### 1. Customer & KYC

Key metrics:
- Total Customers
- Verified Customers
- KYC Verification Rate
- Customer Distribution by KYC Status

### 2. Account & Funding

Key metrics:
- Total Accounts
- Active Accounts
- Total Balance
- Active Balance / AUM Proxy

Recommended breakdown:
- Balance by Tier
- Balance by Account Type
- Account Status Distribution

### 3. Transaction & Usage

Key metrics:
- Transaction Volume
- Transaction Value
- Success Rate
- Failure Rate

Recommended breakdown:
- Monthly Transaction Trend
- Transaction Volume by Channel
- Transaction Value by Merchant Category

### 4. Loan & Credit Risk

Key metrics:
- Total Loans
- Total Principal
- Total Outstanding
- Overdue Rate
- Write-off Rate

Recommended breakdown:
- Loan Portfolio by Loan Type
- Loan Status Distribution
- Outstanding by Loan Type

### 5. Cards

Key metrics:
- Total Cards
- Active Cards
- Credit Cards
- Credit Utilization Rate

Recommended breakdown:
- Cards by Type
- Cards by Status
- Credit Utilization by Account Tier

## Data Source

Dashboard metrics are derived from the SQL analysis files in:

`../sql/`

The main dashboard-ready queries are available in:

`08_dashboard_kpis.sql`

## Important Definitions

**AUM Proxy**

Sum of `balance_idr` for the selected account population. This project uses active accounts as the primary dashboard population.

**KYC Verification Rate**

Verified customers divided by total customer population.

**Transaction Success Rate**

Successful transactions divided by total transactions.

**Credit Utilization**

Credit card outstanding divided by total valid credit limit.

## Dashboard Tool

Recommended visualization tool:

**Power BI**

The dashboard can also be reproduced using Tableau or another BI platform.

## Privacy & Data Limitation

The dataset is simulated/fictitious.

Customer-level PII is not required for dashboard reporting. The dashboard should prioritize aggregated metrics and technical IDs.

Business metrics should not be interpreted as actual performance of a real financial institution.
