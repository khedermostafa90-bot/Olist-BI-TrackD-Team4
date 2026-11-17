USE Olist_BI;
GO

-- =========================================================================
-- G1: Order Status & Monthly Trend (2017-01-01 to 2018-08-31)
-- الفكرة: بنحسب عدد الأوردرات ونسبتها المئوية لكل حالة (تم التوصيل، ملغي...) + التوزيع الشهري
-- =========================================================================
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_orders WHERE order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59') AS DECIMAL(5,2)) AS pct_of_total
FROM olist_orders
WHERE order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
GROUP BY order_status
ORDER BY total_orders DESC;

-- G1 (Part 2): Monthly Breakdown
SELECT 
    FORMAT(order_purchase_timestamp, 'yyyy-MM') AS order_month,
    order_status,
    COUNT(*) AS monthly_orders
FROM olist_orders
WHERE order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM'), order_status
ORDER BY order_month, monthly_orders DESC;

-- =========================================================================
-- G2: Monthly Delivered Revenue, Orders, AOV, and MoM Growth %
-- الفكرة: بنحسب مبيعات الأوردرات الواصلة كل شهر ومتوسط الأوردر (AOV) ونسبة النمو مقارنة بالشهر اللي قبله باستخدام LAG
-- =========================================================================
WITH MonthlySales AS (
    SELECT 
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS sales_month,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        CAST(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id) AS DECIMAL(10,2)) AS avg_order_value
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT 
    sales_month,
    delivered_orders,
    total_revenue,
    avg_order_value,
    CAST((total_revenue - LAG(total_revenue) OVER (ORDER BY sales_month)) * 100.0 
         / NULLIF(LAG(total_revenue) OVER (ORDER BY sales_month), 0) AS DECIMAL(6,2)) AS mom_growth_pct
FROM MonthlySales
ORDER BY sales_month;

-- =========================================================================
-- G3: Data Gaps (Orders missing reviews or payments)
-- الفكرة: بنستخدم LEFT JOIN و NOT EXISTS عشان نطلع الأوردرات اللي ملهاش تقييم أو ملهاش عملية دفع مسجلة
-- =========================================================================
SELECT 
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(DISTINCT CASE WHEN r.order_id IS NULL THEN o.order_id END) AS missing_reviews_count,
    CAST(COUNT(DISTINCT CASE WHEN r.order_id IS NULL THEN o.order_id END) * 100.0 / COUNT(DISTINCT o.order_id) AS DECIMAL(5,2)) AS missing_reviews_pct,
    (SELECT COUNT(*) FROM olist_orders o2 
     WHERE o2.order_status = 'delivered' 
       AND o2.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
       AND NOT EXISTS (SELECT 1 FROM olist_order_payments p WHERE p.order_id = o2.order_id)) AS missing_payments_count
FROM olist_orders o
LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59';
