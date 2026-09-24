# Sakumaya Digital Banking Analytics

SQL-based analytics project exploring customer, account, transaction, loan, and card data from a simulated digital banking / fintech environment.

## Project Overview

This project analyzes Sakumaya, a fictional digital banking business, to understand customer activity, account balances, transaction behavior, lending exposure, and card usage.

The analysis is structured around business questions and emphasizes appropriate analytical grain, data quality validation, clearly defined KPIs, and business interpretation.

## Business Areas

* **Customer & KYC** — customer composition, KYC verification, registration, and referral patterns
* **Accounts & AUM Proxy** — account types, account status, tiers, balances, and customer-account penetration
* **Transactions & Usage** — transaction volume and value, channels, merchant categories, and success/failure patterns
* **Loans & Credit Risk** — loan portfolio, outstanding balances, loan status, overdue/write-off indicators, and borrower patterns
* **Cards** — card portfolio, card status, credit limits, outstanding balances, and credit utilization
* **Cross-Domain Analysis** — relationships between customer funding, transaction activity, card ownership, and credit exposure

## Dataset

The project uses five related tables:

| Table          | Grain                 | Purpose                                   |
| -------------- | --------------------- | ----------------------------------------- |
| `customers`    | 1 row = 1 customer    | Customer master and KYC information       |
| `accounts`     | 1 row = 1 account     | Account, balance, status, and tier        |
| `transactions` | 1 row = 1 transaction | Transaction activity and channels         |
| `loans`        | 1 row = 1 loan        | Lending portfolio and loan status         |
| `cards`        | 1 row = 1 card        | Debit, credit, and prepaid card portfolio |

The dataset is simulated/fictitious and is used as the source of truth for quantitative analysis.

## Analytical Approach

1. Define the business question and analytical grain
2. Validate data quality and table relationships
3. Calculate KPIs using explicit populations and denominators
4. Analyze relevant segments and trends
5. Interpret findings in a business context
6. Document limitations and avoid unsupported causal claims

## Key Metrics

Examples of the KPIs used in the project include:

* KYC verification rate
* Customer/account penetration
* AUM proxy
* Transaction volume and transaction value
* Transaction success/failure rate
* Channel mix
* Loan portfolio and outstanding balance
* Overdue and written-off loan rates
* Credit utilization rate

## Tools

* SQL
* PostgreSQL
* Data Analysis
* Data Cleaning
* Exploratory Data Analysis
* Business Analysis
* Data Quality Validation

## Repository Structure

```text
sakumaya-digital-banking-analytics/
├── README.md
├── sql/
│   ├── 01_data_quality.sql
│   ├── 02_customer_kyc.sql
│   ├── 03_accounts.sql
│   ├── 04_transactions.sql
│   ├── 05_loans.sql
│   └── 06_cards.sql
├── dashboard/
└── images/
```

## Data & Privacy Notes

The dataset contains customer-related fields that may represent PII or semi-PII. Portfolio analysis should therefore prioritize aggregated metrics and technical IDs rather than exposing personal information.

## Limitations

* The dataset represents a simulated business environment, not a real bank.
* Observational relationships should not be interpreted as causal relationships.
* KPI definitions depend on the selected population, denominator, period, and filters.
* AUM is treated as an AUM proxy unless a formal business definition is available.
* Transaction value should not automatically be interpreted as GMV or revenue.
* Overdue and written-off loans are available risk indicators, but should not automatically be labeled as formal NPL without an applicable definition.

## Project Status

**Analysis in progress**

SQL queries, analytical findings, and portfolio visuals will be added as the project is finalized.
