USE Olist_BI;
GO

WITH OrderBaskets AS (
    SELECT 
        o.order_id,
        COUNT(oi.order_item_id) AS item_count,
        COUNT(DISTINCT p.product_category_name) AS distinct_categories,
        COUNT(DISTINCT oi.seller_id) AS distinct_sellers,
        SUM(oi.price + oi.freight_value) AS total_order_value
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    LEFT JOIN olist_products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY o.order_id
)
SELECT 
    CASE WHEN item_count = 1 THEN 'Single-Item Basket' ELSE 'Multi-Item Basket (2+)' END AS basket_type,
    COUNT(*) AS total_orders,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS pct_orders,
    CAST(AVG(item_count * 1.0) AS DECIMAL(5,2)) AS avg_items,
    CAST(AVG(distinct_categories * 1.0) AS DECIMAL(5,2)) AS avg_categories,
    CAST(AVG(distinct_sellers * 1.0) AS DECIMAL(5,2)) AS avg_sellers,
    CAST(AVG(total_order_value) AS DECIMAL(10,2)) AS avg_basket_value
FROM OrderBaskets
GROUP BY CASE WHEN item_count = 1 THEN 'Single-Item Basket' ELSE 'Multi-Item Basket (2+)' END;
GO

WITH OrderCategories AS (
    SELECT DISTINCT 
        o.order_id,
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
)
SELECT TOP 10
    c1.category AS category_1,
    c2.category AS category_2,
    COUNT(DISTINCT c1.order_id) AS pair_order_count,
    CAST(COUNT(DISTINCT c1.order_id) * 100.0 / (SELECT COUNT(DISTINCT order_id) FROM OrderCategories) AS DECIMAL(5,3)) AS pct_of_all_orders
FROM OrderCategories c1
JOIN OrderCategories c2 
    ON c1.order_id = c2.order_id 
   AND ASCII(LEFT(c1.category, 1)) < ASCII(LEFT(c2.category, 1))
GROUP BY c1.category, c2.category
ORDER BY pair_order_count DESC;
GO

WITH Baskets AS (
    SELECT 
        o.order_id,
        COUNT(oi.order_item_id) AS item_count,
        CASE 
            WHEN COUNT(oi.order_item_id) = 1 THEN '1_Item'
            WHEN COUNT(oi.order_item_id) = 2 THEN '2_Items'
            WHEN COUNT(oi.order_item_id) BETWEEN 3 AND 5 THEN '3-5_Items'
            ELSE '6+_Items'
        END AS size_tier,
        SUM(oi.price + oi.freight_value) AS basket_value
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY o.order_id
),
TierStats AS (
    SELECT 
        order_id,
        size_tier,
        basket_value,
        AVG(basket_value) OVER (PARTITION BY size_tier) AS tier_avg_value
    FROM Baskets
)
SELECT 
    size_tier,
    COUNT(*) AS total_baskets_in_tier,
    SUM(CASE WHEN basket_value > tier_avg_value THEN 1 ELSE 0 END) AS above_avg_baskets,
    CAST(SUM(CASE WHEN basket_value > tier_avg_value THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS pct_above_avg,
    CAST(MAX(tier_avg_value) AS DECIMAL(10,2)) AS tier_avg_value,
    CAST(AVG(CASE WHEN basket_value > tier_avg_value THEN basket_value END) AS DECIMAL(10,2)) AS avg_value_of_high_baskets
FROM TierStats
GROUP BY size_tier
ORDER BY size_tier;
GO

WITH Top10Products AS (
    SELECT TOP 10 
        oi.product_id,
        COUNT(*) AS units_sold,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS sales_rank
    FROM olist_order_items oi
    JOIN olist_orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY oi.product_id
    ORDER BY units_sold DESC
),
OrderSummary AS (
    SELECT 
        o.order_id,
        COUNT(oi.order_item_id) AS item_count,
        SUM(oi.price + oi.freight_value) AS basket_value,
        MAX(CASE WHEN t.product_id IS NOT NULL THEN 1 ELSE 0 END) AS has_top10_product
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    LEFT JOIN Top10Products t ON oi.product_id = t.product_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31 23:59:59'
    GROUP BY o.order_id
)
SELECT 
    CASE WHEN has_top10_product = 1 THEN 'Contains Top-10 Product' ELSE 'Other Baskets' END AS basket_group,
    COUNT(*) AS total_orders,
    CAST(AVG(item_count * 1.0) AS DECIMAL(5,2)) AS avg_basket_size,
    CAST(AVG(basket_value) AS DECIMAL(10,2)) AS avg_basket_value,
    CAST(SUM(CASE WHEN item_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS multi_item_pct
FROM OrderSummary
GROUP BY has_top10_product;