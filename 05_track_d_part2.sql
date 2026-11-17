USE Olist_BI;
GO

WITH CatOrders AS (
    SELECT 
        o.order_id,
        MAX(CASE WHEN t.product_category_name_english = 'bed_bath_table' THEN 1 ELSE 0 END) AS has_cat_x,
        MAX(CASE WHEN t.product_category_name_english = 'home_confort' THEN 1 ELSE 0 END) AS has_cat_y,
        SUM(oi.price + oi.freight_value) AS basket_value,
        COUNT(oi.order_item_id) AS item_count
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY o.order_id
)
SELECT 
    CASE 
        WHEN has_cat_x = 1 AND has_cat_y = 0 THEN 'Category X Only (bed_bath_table)'
        WHEN has_cat_x = 1 AND has_cat_y = 1 THEN 'Both X & Y Together'
    END AS purchase_pattern,
    COUNT(*) AS total_orders,
    CAST(AVG(item_count * 1.0) AS DECIMAL(5,2)) AS avg_items,
    CAST(AVG(basket_value) AS DECIMAL(10,2)) AS avg_basket_value
FROM CatOrders
WHERE has_cat_x = 1
GROUP BY CASE 
        WHEN has_cat_x = 1 AND has_cat_y = 0 THEN 'Category X Only (bed_bath_table)'
        WHEN has_cat_x = 1 AND has_cat_y = 1 THEN 'Both X & Y Together'
    END;
GO

WITH MonthlyBaskets AS (
    SELECT 
        o.order_id,
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
        COUNT(oi.order_item_id) AS item_count,
        COUNT(DISTINCT p.product_category_name) AS cat_count
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    LEFT JOIN olist_products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY o.order_id, FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT 
    order_month,
    COUNT(*) AS total_orders,
    CAST(AVG(item_count * 1.0) AS DECIMAL(5,2)) AS avg_items_per_basket,
    CAST(SUM(CASE WHEN cat_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS multi_category_pct
FROM MonthlyBaskets
GROUP BY order_month
ORDER BY order_month;
GO

WITH SellerBaskets AS (
    SELECT 
        o.order_id,
        COUNT(DISTINCT oi.seller_id) AS seller_count,
        SUM(oi.freight_value) AS freight_value,
        SUM(oi.price + oi.freight_value) AS total_value,
        DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_days
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY o.order_id, o.order_purchase_timestamp, o.order_delivered_customer_date
)
SELECT 
    CASE WHEN sb.seller_count = 1 THEN 'Single-Seller Basket' ELSE 'Multi-Seller Basket' END AS seller_type,
    COUNT(*) AS total_orders,
    CAST(AVG(sb.total_value) AS DECIMAL(10,2)) AS avg_total_value,
    CAST(AVG(sb.freight_value) AS DECIMAL(10,2)) AS avg_freight,
    CAST(AVG(sb.delivery_days * 1.0) AS DECIMAL(5,2)) AS avg_delivery_days,
    CAST(AVG(r.review_score * 1.0) AS DECIMAL(4,2)) AS avg_review_score
FROM SellerBaskets sb
LEFT JOIN olist_order_reviews r ON sb.order_id = r.order_id
GROUP BY CASE WHEN sb.seller_count = 1 THEN 'Single-Seller Basket' ELSE 'Multi-Seller Basket' END;
GO

SELECT TOP 10
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN b.item_count > 1 THEN 1 ELSE 0 END) AS multi_item_orders,
    CAST(SUM(CASE WHEN b.item_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT o.order_id) AS DECIMAL(5,2)) AS multi_item_rate_pct
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
JOIN (
    SELECT order_id, COUNT(*) AS item_count
    FROM olist_order_items
    GROUP BY order_id
) b ON o.order_id = b.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY multi_item_rate_pct DESC;
GO

SELECT 
    COUNT(DISTINCT c.customer_unique_id) AS multi_item_customers,
    CAST(AVG(pay.total_paid) AS DECIMAL(10,2)) AS avg_customer_spend
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
JOIN (
    SELECT order_id, SUM(payment_value) AS total_paid
    FROM olist_order_payments
    GROUP BY order_id
) pay ON o.order_id = pay.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
  AND EXISTS (
      SELECT 1 
      FROM olist_order_items oi 
      WHERE oi.order_id = o.order_id 
      GROUP BY oi.order_id 
      HAVING COUNT(*) > 1
  )
  AND pay.total_paid > (
      SELECT AVG(p2.payment_value) 
      FROM olist_order_payments p2
  );