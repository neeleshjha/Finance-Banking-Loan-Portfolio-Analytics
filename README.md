# 🏦 Finance & Banking Loan Portfolio Analytics — End-to-End Data Analyst Project

---

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Problem Statement](#problem-statement)
- [Objectives](#objectives)
- [Dataset Description](#dataset-description)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Steps Involved](#steps-involved)
- [Key Findings](#key-findings)
- [How to Run](#how-to-run)
- [Business Recommendations](#business-recommendations)
- [Skills Demonstrated](#skills-demonstrated)

---

## 🔍 Project Overview

An end-to-end data analytics project examining a **₹5.45B loan portfolio** across 5 banks, 5 regions, and 4 customer segments. The project covers loan performance, credit risk profiling, NPA identification, Net Interest Margin analysis, and branch-level benchmarking — from raw data to executive dashboard.

---

## ❗ Problem Statement

A multi-bank financial group needs a unified risk and performance view to answer critical questions:

- **Which loan grades and customer segments carry unsustainable default risk?**
- **Which branches are underperforming on NPA and why?**
- **How does credit score correlate with interest rate — and are we pricing risk correctly?**
- **Is our Net Interest Margin (NIM) sustainable given current default rates?**

---

## 🎯 Objectives

| # | Objective |
|---|-----------|
| 1 | Profile the full loan portfolio by bank, region, type, and grade |
| 2 | Calculate default rate and NPA rate by loan grade and customer segment |
| 3 | Analyse the relationship between credit score and interest rate |
| 4 | Identify underperforming branches using NPA benchmarking |
| 5 | Build risk-adjusted return and NIM trend models |
| 6 | Create Power BI dashboards for portfolio, risk, and revenue views |

---

## 📊 Dataset Description

**File:** `Finance_DA_Project.xlsx`

| Sheet | Rows | Description |
|-------|------|-------------|
| `Loan_Transactions` | 2,500 | Core loan records — amount, rate, grade, default, NPA, revenue |
| `Branch_Performance` | 25 | Branch-level KPIs: NPA rate, revenue, loan volume |
| `Monthly_KPIs` | 12 | Monthly portfolio metrics: NIM, default rate, disbursements |

### Key Columns

| Column | Type | Description |
|--------|------|-------------|
| `Loan_ID` | Text | Unique loan identifier |
| `Bank` | Category | One of 5 banks in the network |
| `Loan_Grade` | Category | A (lowest risk) → E (highest risk) |
| `Loan_Amount` | Currency | Disbursed loan value |
| `Interest_Rate_Pct` | Decimal % | Annual interest rate charged |
| `Credit_Score` | Integer | Borrower credit score (300–850) |
| `Default_Flag` | Binary (0/1) | 1 = loan in default |
| `NPA_Flag` | Binary (0/1) | 1 = Non-Performing Asset (>90 days overdue) |
| `Revenue` | Currency | Interest + fee revenue earned |
| `NIM_Pct` | Decimal % | Net Interest Margin for this loan |
| `Customer_Segment` | Category | Retail / SME / Corporate / Private Banking |

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **Microsoft Excel** | Data cleaning, loan grade pivot, branch comparison |
| **SQL** | 14 advanced queries, LAG/RANK/NTILE, 2 views |
| **Python 3.8+** | EDA, 7-chart risk dashboard, correlation analysis |
| **Tableau Desktop / Public** | 3 interactive dashboards |
| **PowerPoint** | 9-slide executive risk presentation |

---

## 📁 Project Structure

```
finance-banking-analytics/
│
├── data/
│   └── Finance_DA_Project.xlsx
│
├── sql/
│   └── Finance_SQL_Queries.sql
│
├── python/
│   └── Finance_Python_EDA.py
│
├── tableau/
│   └── Finance_Tableau.twbx
│
├── powerbi/
│   └── Finance_PowerBI_Scripts.m
│
├── presentation/
│   └── Finance_Banking_Presentation.pptx
│
├── outputs/
│   ├── Finance_EDA_Dashboard.png
│   └── Finance_Risk_Analysis.png
│
└── README.md
```

---

## 🔢 Steps Involved

### Phase 1 — Data Cleaning & Excel
1. Load loan records; fix date formats on `Disbursement_Date`
2. Remove duplicate `Loan_ID` entries; validate `Loan_Grade` values (A–E only)
3. Compute `Default_Rate` and `NPA_Rate` columns using AVERAGEIF per bank
4. Pivot: Default Rate by Grade × Bank; NPA Rate by Region × Segment
5. Conditional formatting: red if `Default_Flag = 1`; amber if `Credit_Score < 600`

### Phase 2 — SQL Analysis
6. Data quality checks: null counts, negative loan amounts, invalid grades (Q1–Q2)
7. Portfolio profiling: loan breakdown by bank, region, type, grade (Q3–Q5)
8. Credit risk analysis: default/NPA by grade and segment; credit score distribution (Q6–Q8)
9. Revenue analysis: NIM by loan type; revenue by segment; interest rate pricing (Q9–Q10)
10. Advanced SQL: LAG() for MoM default change; RANK() branch NPA ranking; NTILE() credit quartiles; NIM CTE (Q11–Q14)
11. Create `vw_Portfolio_Summary` and `vw_Risk_Dashboard` views

### Phase 3 — Python EDA
12. Load data from Excel sheets with `pandas.read_excel()`
13. Statistical summary: portfolio value, default/NPA rates, avg credit score, NIM
14. EDA Figure 1 (7 charts): portfolio by bank, default by grade, NPA by region, NIM trend, credit score histogram, revenue by segment, interest rate distribution
15. EDA Figure 2 (risk deep-dive): credit score vs interest rate scatter (r = −0.93), default rate by grade bar, NPA heatmap (bank × region)

### Phase 4 — Tableau Dashboards
16. Open `Finance_Tableau.twbx` — data pre-embedded
17. Dashboard 1 — Portfolio Overview: disbursement trend, portfolio by bank, loan type mix
18. Dashboard 2 — Risk Dashboard: default by grade (traffic-light), NPA by bank, credit score distribution, at-risk portfolio gauge
19. Dashboard 3 — Revenue & Branches: revenue by segment, branch NPA scatter, NIM trend, revenue by channel

### Phase 5 — Presentation
20. Build 9-slide executive risk deck with Midnight Navy + Gold theme

---

## 📈 Key Findings

| Finding | Detail |
|---------|--------|
| 🔴 Grade-E default rate: 19.7% | 28× higher than Grade-A (0.7%) |
| 🏦 City Trust Bank – West: highest NPA | Network-wide outlier requiring audit |
| 📉 Credit Score vs Interest Rate | r = −0.93 near-perfect inverse correlation |
| 💳 Private Banking highest NPA by segment | 4.7% — driven by SME loan exposure |
| 📊 Total Portfolio: ₹5.45B | Avg NIM: 3.79% across the network |

---

## 💼 Business Recommendations

1. **Halt Grade-E new originations** — 19.7% default rate destroys NIM; implement Grade-D ceiling on unsecured retail loans
2. **Audit City Trust Bank West branch** — NPA outlier signals portfolio concentration or underwriting failure
3. **Automate credit score-based pricing** — r = −0.93 confirms score drives rate; productise this into the origination system
4. **Private Banking segment review** — 4.7% NPA requires collateral reassessment on top-50 accounts

---

## 🧠 Skills Demonstrated

`Loan Portfolio Analysis` · `Credit Risk Modelling` · `NPA Rate Calculation` · `NIM Analysis` · `SQL RANK/LAG/NTILE` · `CTE Chains` · `Python Correlation Analysis` · `Risk Dashboard Design` · `Tableau` · `DAX` · `Power Query M` · `Executive Presentation`
