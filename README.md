#  E-Commerce SQL Analytics Project  
**End-to-End Business, Customer & Operations Analysis**

---

##  Project Overview

This project analyzes an e-commerce dataset using SQL to evaluate:

- Revenue performance  
- Product concentration risk  
- Customer retention & lifetime value  
- Delivery performance & operational impact  
- Revenue risk from poor customer experience  

The goal is to simulate a real-world analytics case study and answer executive-level business questions using structured data modeling and advanced SQL techniques.

---

#  Data Modeling Approach

The project follows a simplified **star-schema analytical structure**.

##  Fact Table
### fact_orders`
- `order_id`
- `customer_id`
- `order_date`
- `order_month`
- `order_revenue`
- `delivery_days`
- `status`

##  Dimension Tables
- `dim_customers` – city, signup_date, first_order_date  
- `dim_products` – category, product_name  
- `reviews` – order_id, score, review_date  
- `clean_orders` – delivery & SLA logic  

---

##  Data Preparation

Before analysis, the following steps were performed:

- Created clean views to filter only delivered orders  
- Engineered `delivery_days`  
- Created SLA breach flags  
- Built reusable customer segmentation logic  
- Defined cohort months for retention analysis  
- Created delivery buckets (0–2, 3–5, 6+ days)  
- Classified ratings (Low / Neutral / High)  

This modular structure ensures reusable and scalable queries.

---

#  PHASE 3.1 — Revenue & Growth Analysis

### Key Questions
- Is revenue growing consistently?
- Is growth volume-driven or pricing-driven?
- Are there abnormal revenue months?

### Insights
- Revenue growth fluctuates.
- Order growth and revenue growth do not always align → product mix / pricing shifts.
- Some abnormal revenue drops detected via Z-score.

### Conclusion
Growth exists but quality of growth varies month-to-month.

### Recommendation
Track AOV alongside order volume and monitor revenue volatility monthly.

---

#  PHASE 3.2 — Product & Category Performance

### Key Questions
- Which categories drive revenue?
- Is revenue concentrated in few SKUs?
- Is there SKU concentration risk?

### Insights
- Electronics contributes ~64% of revenue.
- Top 10% customers contribute ~27% of revenue.
- Few SKUs dominate each category.
- Revenue concentration risk exists.

### Conclusion
Business has moderate dependency on top categories and products.

### Recommendation
Diversify high-performing categories and reduce SKU concentration risk.

---

#  PHASE 3.3 — Customer Behaviour & Retention

## 1️ Customer Distribution
- 17% single-order customers
- 66% mid-frequency (2–4 orders)
- 17% loyal (5+ orders)

## 2️ Revenue Contribution
- Repeat customers drive majority of revenue.
- Loyal segment drives disproportionately high LTV.

## 3️ LTV Analysis
- Loyal customers have significantly higher lifetime value.
- Slight LTV decline in newer cohorts.

## 4️ New vs Repeat Revenue
Revenue has shifted from acquisition-led to retention-led growth.

## 5️ Cohort Analysis
Older cohorts retain slightly better than recent cohorts.

## 6️ Repeat Purchase Gap
- Average repeat cycle ≈ 227 days.
- Loyal customers reorder faster (~163 days).
- Repeat cycle increasing over time → potential engagement slowdown.

## 7️ Churn (270-day threshold)
Overall churn ≈ 59%.

Segment churn:
- 1-order → 77%
- 2–4 → 45%
- 5+ → 20%

### Conclusion
Business is retention-driven but repeat cycle is slowing.

### Recommendation
Accelerate repeat purchases and protect high-value customers.

---

#  PHASE 3.4 — Operations & Reviews

## 1️ Delivery Performance
- Avg delivery: 2 days
- 59% delivered within 0–2 days
- ~10% SLA breaches

## 2️ Ratings
- Avg rating: 3
- 6.5% low ratings (1–2 stars)

## 3️ Delivery Speed vs Rating

| Delivery Time | Avg Rating |
|---------------|------------|
| 0–2 days | 4 |
| 3–5 days | 3 |
| 6+ days | 2 |

Clear threshold effect:  
Beyond 3 days → satisfaction drops sharply.

## 4️ Revenue Impact
Low-rated customers:
- Lower reorder rate
- Lower future revenue

Operational issues directly affect retention and revenue.

### Conclusion
Delivery speed strongly influences satisfaction and long-term value.

### Recommendation
Prioritize reducing deliveries beyond 3 days.  
Investigate logistics tail (6+ days).

---

#  Executive Summary

This business shows:

✅ Strong repeat-customer driven revenue  
✅ Operational efficiency in majority of orders  
⚠️ Moderate revenue concentration risk  
⚠️ Slowing repeat purchase cycle  
⚠️ Clear satisfaction threshold tied to delivery speed  

Delivery performance impacts both ratings and future revenue.

---

#  Key Skills Demonstrated

- Advanced SQL (CTEs, window functions, NTILE, RANK, LAG)
- Cohort analysis
- Retention modeling
- Churn definition
- Revenue concentration analysis
- SLA breach analytics
- Behavioral segmentation
- Multi-table joins & modular view design

---

#  Business Impact Takeaways

If the company:

- Improves delivery speed beyond 3 days  
- Protects top 10% customers  
- Reduces repeat purchase gap  

It can significantly improve long-term LTV and revenue stability.

---

#  How to Run

1. Create tables using provided schema.
2. Load CSV data via BULK INSERT.
3. Create clean views.
4. Run phase-wise analysis queries.

---

#  Author

**Sahil Jangid**  
SQL | Analytics | Retention & Growth Modeling  

---
