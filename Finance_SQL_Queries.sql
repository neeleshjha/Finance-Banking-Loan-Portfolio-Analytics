-- ============================================================
--  FINANCE / BANKING ANALYTICS PROJECT — SQL QUERIES
--  Database: Bank Loan Portfolio (SQLite compatible)
--  Coverage: Portfolio KPIs · Risk Analysis · Revenue · NPA
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- PHASE 1: SCHEMA & SETUP
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS loan_transactions (
    Loan_ID              TEXT PRIMARY KEY,
    Bank                 TEXT,
    Region               TEXT,
    Customer_Segment     TEXT,
    Loan_Type            TEXT,
    Channel              TEXT,
    Risk_Grade           TEXT,
    Loan_Amount          REAL,
    Interest_Rate_Pct    REAL,
    Tenure_Months        INTEGER,
    Monthly_EMI          REAL,
    Net_Interest_Income  REAL,
    Credit_Score         INTEGER,
    Customer_Age         INTEGER,
    Collateral_Ratio     REAL,
    Disbursement_Date    DATE,
    Is_Default           INTEGER,   -- 0/1
    Is_NPA               INTEGER,   -- 0/1
    Account_Type         TEXT
);

CREATE TABLE IF NOT EXISTS branch_performance (
    Bank                        TEXT,
    Region                      TEXT,
    Branch_Code                 TEXT PRIMARY KEY,
    Total_Loans_Disbursed       INTEGER,
    Total_Deposits              REAL,
    CASA_Ratio_Pct              REAL,
    NPA_Ratio_Pct               REAL,
    Net_Interest_Margin_Pct     REAL,
    Customer_Acquisition_Cost   REAL,
    Attrition_Rate_Pct          REAL,
    Staff_Count                 INTEGER
);

-- ────────────────────────────────────────────────────────────
-- PHASE 2: DATA QUALITY CHECKS
-- ────────────────────────────────────────────────────────────

-- Q1: Dataset overview
SELECT
    COUNT(*)                           AS Total_Loans,
    MIN(Disbursement_Date)             AS Earliest_Date,
    MAX(Disbursement_Date)             AS Latest_Date,
    COUNT(DISTINCT Bank)               AS Banks,
    COUNT(DISTINCT Loan_Type)          AS Loan_Types,
    COUNT(DISTINCT Customer_Segment)   AS Segments,
    SUM(CASE WHEN Loan_Amount <= 0 THEN 1 ELSE 0 END) AS Invalid_Amounts,
    SUM(CASE WHEN Credit_Score < 300 OR Credit_Score > 900 THEN 1 ELSE 0 END) AS Invalid_Scores
FROM loan_transactions;

-- Q2: Risk grade distribution
SELECT
    Risk_Grade,
    COUNT(*)                              AS Loan_Count,
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM loan_transactions),1) AS Pct_of_Portfolio,
    ROUND(AVG(Credit_Score),0)            AS Avg_Credit_Score,
    ROUND(AVG(Interest_Rate_Pct),2)       AS Avg_Rate_Pct,
    ROUND(SUM(Loan_Amount)/1e6,1)         AS Total_Volume_M
FROM loan_transactions
GROUP BY Risk_Grade
ORDER BY Risk_Grade;

-- ────────────────────────────────────────────────────────────
-- PHASE 3: PORTFOLIO KPIs
-- ────────────────────────────────────────────────────────────

-- Q3: Bank-level portfolio summary
SELECT
    Bank,
    COUNT(*)                                     AS Total_Loans,
    ROUND(SUM(Loan_Amount)/1e9, 2)              AS Portfolio_Bn,
    ROUND(AVG(Interest_Rate_Pct), 2)            AS Avg_Rate_Pct,
    ROUND(AVG(Credit_Score), 0)                 AS Avg_Credit_Score,
    ROUND(AVG(Is_Default)*100, 1)               AS Default_Rate_Pct,
    ROUND(AVG(Is_NPA)*100, 2)                   AS NPA_Rate_Pct,
    ROUND(SUM(Net_Interest_Income)/1e9, 2)      AS NII_Bn
FROM loan_transactions
GROUP BY Bank
ORDER BY Portfolio_Bn DESC;

-- Q4: Monthly disbursement trend
SELECT
    STRFTIME('%Y-%m', Disbursement_Date)         AS Month,
    COUNT(*)                                     AS Loans_Count,
    ROUND(SUM(Loan_Amount)/1e9, 2)              AS Volume_Bn,
    ROUND(AVG(Interest_Rate_Pct), 2)            AS Avg_Rate,
    SUM(Is_Default)                             AS Defaults,
    ROUND(AVG(Is_Default)*100, 2)               AS Default_Rate_Pct,
    ROUND(SUM(Net_Interest_Income)/1e6, 1)      AS NII_M
FROM loan_transactions
GROUP BY Month
ORDER BY Month;

-- Q5: Loan type profitability analysis
SELECT
    Loan_Type,
    COUNT(*)                                     AS Loan_Count,
    ROUND(SUM(Loan_Amount)/1e6, 1)              AS Total_Volume_M,
    ROUND(AVG(Loan_Amount), 0)                  AS Avg_Loan_Amt,
    ROUND(AVG(Interest_Rate_Pct), 2)            AS Avg_Rate_Pct,
    ROUND(AVG(Is_Default)*100, 1)               AS Default_Rate_Pct,
    ROUND(SUM(Net_Interest_Income)/1e6, 1)      AS Total_NII_M,
    ROUND(SUM(Net_Interest_Income)/SUM(Loan_Amount)*100, 2) AS NII_Yield_Pct
FROM loan_transactions
GROUP BY Loan_Type
ORDER BY Total_NII_M DESC;

-- ────────────────────────────────────────────────────────────
-- PHASE 4: RISK & NPA ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Q6: NPA analysis by segment & region
SELECT
    Customer_Segment,
    Region,
    COUNT(*)                                     AS Loans,
    SUM(Is_NPA)                                 AS NPA_Count,
    ROUND(AVG(Is_NPA)*100, 2)                   AS NPA_Rate_Pct,
    ROUND(SUM(CASE WHEN Is_NPA=1 THEN Loan_Amount ELSE 0 END)/1e6, 1) AS NPA_Value_M,
    ROUND(AVG(Credit_Score), 0)                 AS Avg_Credit_Score
FROM loan_transactions
GROUP BY Customer_Segment, Region
ORDER BY NPA_Rate_Pct DESC;

-- Q7: High-risk loan identification
SELECT
    Loan_ID,
    Bank,
    Customer_Segment,
    Loan_Type,
    Risk_Grade,
    Credit_Score,
    Loan_Amount,
    Interest_Rate_Pct,
    Collateral_Ratio,
    Is_Default,
    Is_NPA
FROM loan_transactions
WHERE Risk_Grade IN ('D','E')
  AND Credit_Score < 580
  AND Loan_Amount > 500000
ORDER BY Loan_Amount DESC
LIMIT 20;

-- Q8: Collateral coverage analysis
SELECT
    Loan_Type,
    CASE
        WHEN Collateral_Ratio = 0              THEN 'Unsecured'
        WHEN Collateral_Ratio < 1.0            THEN 'Under-Collateralised'
        WHEN Collateral_Ratio BETWEEN 1.0 AND 1.5 THEN 'Adequate'
        ELSE 'Over-Collateralised'
    END AS Collateral_Band,
    COUNT(*)                                     AS Loans,
    ROUND(AVG(Interest_Rate_Pct), 2)            AS Avg_Rate,
    ROUND(AVG(Is_Default)*100, 1)               AS Default_Rate_Pct,
    ROUND(AVG(Loan_Amount), 0)                  AS Avg_Loan_Amt
FROM loan_transactions
WHERE Loan_Type IN ('Home Loan','Auto Loan','Business Loan')
GROUP BY Loan_Type, Collateral_Band
ORDER BY Loan_Type, Default_Rate_Pct DESC;

-- ────────────────────────────────────────────────────────────
-- PHASE 5: REVENUE & PROFITABILITY
-- ────────────────────────────────────────────────────────────

-- Q9: NIM & CASA analysis by bank and region
SELECT
    b.Bank,
    b.Region,
    b.NPA_Ratio_Pct,
    b.Net_Interest_Margin_Pct,
    b.CASA_Ratio_Pct,
    b.Attrition_Rate_Pct,
    b.Customer_Acquisition_Cost,
    ROUND(b.Total_Deposits/1e6, 1)               AS Deposits_M
FROM branch_performance b
ORDER BY b.Net_Interest_Margin_Pct DESC;

-- Q10: Revenue contribution by customer segment
SELECT
    l.Customer_Segment,
    COUNT(*)                                     AS Loan_Count,
    ROUND(SUM(l.Loan_Amount)/1e9, 2)            AS Portfolio_Bn,
    ROUND(AVG(l.Interest_Rate_Pct), 2)          AS Avg_Rate_Pct,
    ROUND(SUM(l.Net_Interest_Income)/1e9, 3)    AS NII_Bn,
    ROUND(SUM(l.Net_Interest_Income)/SUM(l.Loan_Amount)*100, 2) AS NII_Yield_Pct,
    ROUND(AVG(l.Is_Default)*100, 1)             AS Default_Rate_Pct
FROM loan_transactions l
GROUP BY l.Customer_Segment
ORDER BY NII_Bn DESC;

-- ────────────────────────────────────────────────────────────
-- PHASE 6: ADVANCED SQL (CTEs + Window Functions)
-- ────────────────────────────────────────────────────────────

-- Q11: Running total of NII and month-over-month growth
WITH Monthly_NII AS (
    SELECT
        STRFTIME('%Y-%m', Disbursement_Date)         AS Month,
        ROUND(SUM(Net_Interest_Income)/1e6, 1)      AS NII_M,
        COUNT(*)                                    AS Loans
    FROM loan_transactions
    GROUP BY Month
)
SELECT
    Month,
    Loans,
    NII_M,
    SUM(NII_M) OVER (ORDER BY Month)               AS Cumulative_NII_M,
    ROUND(
        (NII_M - LAG(NII_M) OVER (ORDER BY Month)) /
        LAG(NII_M) OVER (ORDER BY Month) * 100, 1
    ) AS MoM_Growth_Pct,
    ROUND(AVG(NII_M) OVER (
        ORDER BY Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1)                                           AS Rolling_3M_NII_M
FROM Monthly_NII
ORDER BY Month;

-- Q12: Rank banks by NPA rate within each region
WITH BankRisk AS (
    SELECT
        Bank,
        Region,
        COUNT(*)                         AS Loans,
        ROUND(AVG(Is_NPA)*100, 2)       AS NPA_Rate,
        ROUND(SUM(Loan_Amount)/1e6, 1)  AS Portfolio_M
    FROM loan_transactions
    GROUP BY Bank, Region
)
SELECT
    Bank,
    Region,
    Loans,
    Portfolio_M,
    NPA_Rate,
    RANK()    OVER (PARTITION BY Region ORDER BY NPA_Rate ASC)  AS Rank_In_Region,
    RANK()    OVER (ORDER BY NPA_Rate ASC)                      AS Overall_Rank,
    NTILE(4)  OVER (ORDER BY NPA_Rate ASC)                      AS NPA_Quartile
FROM BankRisk
ORDER BY Region, NPA_Rate;

-- Q13: Credit score buckets with default probability
WITH CreditBuckets AS (
    SELECT
        CASE
            WHEN Credit_Score >= 800 THEN '800-850  Excellent'
            WHEN Credit_Score >= 750 THEN '750-799  Very Good'
            WHEN Credit_Score >= 700 THEN '700-749  Good'
            WHEN Credit_Score >= 650 THEN '650-699  Fair'
            WHEN Credit_Score >= 600 THEN '600-649  Poor'
            ELSE                          '300-599  Very Poor'
        END AS Credit_Band,
        Loan_Amount, Is_Default, Is_NPA, Interest_Rate_Pct
    FROM loan_transactions
)
SELECT
    Credit_Band,
    COUNT(*)                                     AS Loans,
    ROUND(AVG(Is_Default)*100, 1)               AS Default_Rate_Pct,
    ROUND(AVG(Is_NPA)*100, 1)                   AS NPA_Rate_Pct,
    ROUND(AVG(Interest_Rate_Pct), 2)            AS Avg_Rate_Pct,
    ROUND(AVG(Loan_Amount), 0)                  AS Avg_Loan_Amt
FROM CreditBuckets
GROUP BY Credit_Band
ORDER BY Credit_Band DESC;

-- Q14: Customer lifetime value proxy (JOIN loan + branch)
WITH CustomerValue AS (
    SELECT
        l.Bank,
        l.Customer_Segment,
        l.Risk_Grade,
        ROUND(AVG(l.Net_Interest_Income), 0)    AS Avg_NII_Per_Loan,
        ROUND(AVG(l.Loan_Amount), 0)            AS Avg_Loan_Amt,
        ROUND(AVG(l.Is_Default)*100, 1)         AS Default_Rate_Pct,
        COUNT(*)                                AS Loan_Count
    FROM loan_transactions l
    GROUP BY l.Bank, l.Customer_Segment, l.Risk_Grade
)
SELECT
    cv.Bank,
    cv.Customer_Segment,
    cv.Risk_Grade,
    cv.Loan_Count,
    cv.Avg_Loan_Amt,
    cv.Avg_NII_Per_Loan,
    cv.Default_Rate_Pct,
    bp.CASA_Ratio_Pct,
    bp.Net_Interest_Margin_Pct,
    bp.Customer_Acquisition_Cost,
    ROUND(cv.Avg_NII_Per_Loan - bp.Customer_Acquisition_Cost, 0) AS Net_Customer_Value
FROM CustomerValue cv
JOIN branch_performance bp ON cv.Bank = bp.Bank
GROUP BY cv.Bank, cv.Customer_Segment, cv.Risk_Grade
ORDER BY Net_Customer_Value DESC
LIMIT 20;

-- ────────────────────────────────────────────────────────────
-- PHASE 7: VIEWS FOR TABLEAU
-- ────────────────────────────────────────────────────────────

CREATE VIEW IF NOT EXISTS vw_Portfolio_Summary AS
SELECT
    Bank, Region, Customer_Segment, Loan_Type, Risk_Grade,
    STRFTIME('%Y-%m', Disbursement_Date)         AS Month,
    COUNT(*)                                     AS Loans,
    ROUND(SUM(Loan_Amount)/1e6, 1)              AS Portfolio_M,
    ROUND(AVG(Interest_Rate_Pct), 2)            AS Avg_Rate,
    ROUND(AVG(Is_Default)*100, 2)               AS Default_Rate_Pct,
    ROUND(AVG(Is_NPA)*100, 2)                   AS NPA_Rate_Pct,
    ROUND(SUM(Net_Interest_Income)/1e6, 2)      AS NII_M
FROM loan_transactions
GROUP BY Bank, Region, Customer_Segment, Loan_Type, Risk_Grade, Month;

CREATE VIEW IF NOT EXISTS vw_Risk_Dashboard AS
SELECT
    l.Bank, l.Region, l.Risk_Grade, l.Customer_Segment,
    COUNT(*)                                     AS Loans,
    SUM(l.Is_NPA)                               AS NPA_Count,
    ROUND(AVG(l.Is_NPA)*100, 2)                 AS NPA_Rate_Pct,
    ROUND(SUM(l.Loan_Amount)/1e6, 1)            AS Portfolio_M,
    ROUND(AVG(l.Credit_Score), 0)               AS Avg_Score,
    b.NPA_Ratio_Pct                             AS Branch_NPA_Pct,
    b.Net_Interest_Margin_Pct                   AS Branch_NIM_Pct
FROM loan_transactions l
JOIN branch_performance b ON l.Bank = b.Bank AND l.Region = b.Region
GROUP BY l.Bank, l.Region, l.Risk_Grade, l.Customer_Segment;
