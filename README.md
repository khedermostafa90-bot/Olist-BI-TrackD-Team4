# Olist E-Commerce Business Intelligence Project — Track D (Shopping Baskets)

## Project Overview
This project analyzes the Brazilian E-Commerce Public Dataset by Olist using SQL Server (T-SQL) and Microsoft Excel to uncover shopping basket patterns, product co-occurrence, and multi-seller dynamics for Team 4 (Track D: Shopping Baskets).

## Repository Structure
* 01_schema_and_import.sql — Database creation, table constraints (PK/FK), and bulk data import.
* 03_general_questions.sql — General queries (G1–G3): Order status distribution, monthly revenue & MoM growth (LAG), and data gap checks (LEFT JOIN & NOT EXISTS).
* 04_track_d_part1.sql — Track D queries (D1–D4): Basket structure, self-join category pairs, size-tier benchmarking (AVG OVER), and Top-10 product impact (RANK).
* 05_track_d_part2_and_optional.sql — Track D & Optional queries (D5–D7, O1–O2): Category affinity, monthly composition trends, single vs. multi-seller performance, and high-value customer segmentation.
* Olist_TrackD_Dashboard.xlsx — Interactive Excel Dashboard featuring 4 KPIs, 3 PivotCharts, and 2 connected Slicers (Order_Month and State).
* TrackD_Report_Team4.pdf — Complete executive report with ERD schema, data dictionary, SQL insights, and business recommendations.

## How to Run
1. Download the Olist dataset from Kaggle and place CSV files in the target directory.
2. Execute 01_schema_and_import.sql in SQL Server Management Studio (SSMS) to build Olist_BI.
3. Run the analytical scripts (03 through 05) to reproduce all query results.
4. Open Olist_TrackD_Dashboard.xlsx to explore the interactive charts using the Month and State slicers.
