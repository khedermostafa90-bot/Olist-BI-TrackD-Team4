USE Olist_BI;
GO

BULK INSERT olist_customers FROM 'C:\Users\Public\pjBi\olist_customers_dataset_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT olist_sellers FROM 'C:\Users\Public\pjBi\olist_sellers_dataset_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT olist_geolocation FROM 'C:\Users\Public\pjBi\olist_geolocation_dataset_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT product_category_name_translation FROM 'C:\Users\Public\pjBi\product_category_name_translation_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT olist_products FROM 'C:\Users\Public\pjBi\olist_products_dataset_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT olist_orders FROM 'C:\Users\Public\pjBi\olist_orders_dataset_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT olist_order_items FROM 'C:\Users\Public\pjBi\olist_order_items_dataset_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT olist_order_payments FROM 'C:\Users\Public\pjBi\olist_order_payments_dataset_pipe.txt' WITH (FIRSTROW = 2, FIELDTERMINATOR = '|', ROWTERMINATOR = '\n', CODEPAGE = '65001');
GO

SELECT 'customers' AS TableName, COUNT(*) AS Row_Count FROM olist_customers
UNION ALL SELECT 'sellers', COUNT(*) FROM olist_sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM olist_geolocation
UNION ALL SELECT 'translation', COUNT(*) FROM product_category_name_translation
UNION ALL SELECT 'products', COUNT(*) FROM olist_products
UNION ALL SELECT 'orders', COUNT(*) FROM olist_orders
UNION ALL SELECT 'order_items', COUNT(*) FROM olist_order_items
UNION ALL SELECT 'payments', COUNT(*) FROM olist_order_payments
UNION ALL SELECT 'reviews', COUNT(*) FROM olist_order_reviews;